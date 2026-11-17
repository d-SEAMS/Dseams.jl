#!/usr/bin/env python3
"""Add and validate search metadata on every generated Documenter page."""

import argparse
import html
import json
import re
import sys
from pathlib import Path
from urllib.parse import quote
from xml.etree import ElementTree

DESCRIPTION = (
    "Julia documentation for d-SEAMS molecular trajectory analysis, including "
    "ice classification, clathrate cages, and primitive rings."
)
DOI = "https://doi.org/10.1021/acs.jcim.0c00031"
REPOSITORY = "https://github.com/d-SEAMS/Dseams.jl"
SITE_NAME = "Dseams.jl documentation"
SOCIAL_IMAGE = "https://dseams.info/images/og-card.png"
START = "<!-- dseams-seo:start -->"
END = "<!-- dseams-seo:end -->"


def canonical_url(base_url, relative):
    path = relative.as_posix()
    if path == "index.html":
        path = ""
    elif path.endswith("/index.html"):
        path = path[: -len("index.html")]
    return base_url.rstrip("/") + "/" + quote(path, safe="/.-~")


def page_title(text, relative):
    match = re.search(r"<title\b[^>]*>(.*?)</title\s*>", text, re.I | re.S)
    if match:
        title = html.unescape(re.sub(r"<[^>]+>", "", match.group(1))).strip()
        if title:
            return re.sub(r"\s+", " ", title)
    label = relative.stem.replace("-", " ").replace("_", " ").strip().title()
    return f"{label or 'Documentation'} · {SITE_NAME}"


def strip_metadata(text):
    text = re.sub(
        re.escape(START) + r".*?" + re.escape(END) + r"\s*",
        "",
        text,
        flags=re.S,
    )
    text = re.sub(
        r"<meta\b(?=[^>]*\bname\s*=\s*['\"]description['\"])[^>]*>\s*",
        "",
        text,
        flags=re.I,
    )
    text = re.sub(
        r"<link\b(?=[^>]*\brel\s*=\s*['\"]canonical['\"])[^>]*>\s*",
        "",
        text,
        flags=re.I,
    )
    text = re.sub(
        r"<meta\b(?=[^>]*\b(?:name|property)\s*=\s*['\"](?:og|twitter):)[^>]*>\s*",
        "",
        text,
        flags=re.I,
    )
    return text


def metadata(title, description, canonical, sitemap):
    graph = {
        "@context": "https://schema.org",
        "@graph": [
            {
                "@type": "SoftwareApplication",
                "name": "Dseams.jl",
                "applicationCategory": "ScientificApplication",
                "operatingSystem": "Linux, macOS, Windows",
                "url": canonical,
                "citation": DOI,
            },
            {
                "@type": "SoftwareSourceCode",
                "name": "Dseams.jl",
                "codeRepository": REPOSITORY,
                "programmingLanguage": "Julia",
                "url": REPOSITORY,
                "citation": DOI,
            },
        ],
    }
    title = html.escape(title, quote=True)
    description = html.escape(description, quote=True)
    canonical = html.escape(canonical, quote=True)
    sitemap = html.escape(sitemap, quote=True)
    return "\n".join(
        [
            START,
            f'<meta name="description" content="{description}">',
            f'<link rel="canonical" href="{canonical}">',
            f'<link rel="sitemap" type="application/xml" href="{sitemap}">',
            '<meta property="og:type" content="website">',
            f'<meta property="og:site_name" content="{html.escape(SITE_NAME, quote=True)}">',
            f'<meta property="og:title" content="{title}">',
            f'<meta property="og:description" content="{description}">',
            f'<meta property="og:url" content="{canonical}">',
            f'<meta property="og:image" content="{SOCIAL_IMAGE}">',
            '<meta name="twitter:card" content="summary">',
            f'<meta name="twitter:title" content="{title}">',
            f'<meta name="twitter:description" content="{description}">',
            f'<meta name="twitter:image" content="{SOCIAL_IMAGE}">',
            '<script type="application/ld+json">'
            + json.dumps(graph, ensure_ascii=False, separators=(",", ":"))
            + "</script>",
            END,
        ]
    )


def apply(root, base_url):
    pages = sorted(root.rglob("*.html"))
    if not pages:
        raise ValueError(f"no HTML pages found in {root}")
    titles = {}
    prepared = []
    for path in pages:
        text = strip_metadata(path.read_text(encoding="utf-8", errors="replace"))
        relative = path.relative_to(root)
        title = page_title(text, relative)
        titles[title] = titles.get(title, 0) + 1
        prepared.append((path, relative, text, title))

    urls = []
    for path, relative, text, title in prepared:
        if titles[title] > 1:
            title = f"{title} ({relative.as_posix()})"
        description = f"{title}. {DESCRIPTION}"
        canonical = canonical_url(base_url, relative)
        title_tag = f"<title>{html.escape(title)}</title>"
        if re.search(r"<title\b[^>]*>.*?</title\s*>", text, re.I | re.S):
            text = re.sub(
                r"<title\b[^>]*>.*?</title\s*>",
                title_tag,
                text,
                count=1,
                flags=re.I | re.S,
            )
        else:
            text = re.sub(
                r"<head\b[^>]*>",
                lambda match: match.group(0) + "\n" + title_tag,
                text,
                count=1,
                flags=re.I,
            )
        if not re.search(r"</head\s*>", text, re.I):
            raise ValueError(f"{relative} has no closing head element")
        text = re.sub(
            r"</head\s*>",
            metadata(
                title,
                description,
                canonical,
                canonical_url(base_url, Path("sitemap.xml")),
            )
            + "\n</head>",
            text,
            count=1,
            flags=re.I,
        )
        path.write_text(text, encoding="utf-8")
        if relative.name != "404.html" and not re.search(
            r'<meta\b[^>]*name=["\']robots["\'][^>]*content=["\'][^"\']*noindex',
            text,
            re.I,
        ):
            urls.append(canonical)

    sitemap = ElementTree.Element(
        "urlset", xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
    )
    for url in urls:
        node = ElementTree.SubElement(sitemap, "url")
        ElementTree.SubElement(node, "loc").text = url
    ElementTree.ElementTree(sitemap).write(
        root / "sitemap.xml", encoding="utf-8", xml_declaration=True
    )
    (root / "robots.txt").write_text(
        "User-agent: *\nAllow: /\n"
        f"Sitemap: {canonical_url(base_url, Path('sitemap.xml'))}\n",
        encoding="utf-8",
    )


def attribute(text, element, key, value):
    return re.search(
        rf"<{element}\b(?=[^>]*\b{key}\s*=\s*['\"]{re.escape(value)}['\"])[^>]*>",
        text,
        re.I,
    )


def content(tag):
    match = re.search(r'\bcontent\s*=\s*["\']([^"\']*)', tag.group(0), re.I)
    return html.unescape(match.group(1)).strip() if match else ""


def href(tag):
    match = re.search(r'\bhref\s*=\s*["\']([^"\']*)', tag.group(0), re.I)
    return html.unescape(match.group(1)).strip() if match else ""


def check(root, base_url):
    pages = sorted(root.rglob("*.html"))
    if not pages:
        raise ValueError(f"no HTML pages found in {root}")
    titles = {}
    descriptions = {}
    errors = []
    for path in pages:
        relative = path.relative_to(root)
        text = path.read_text(encoding="utf-8", errors="replace")
        title = re.search(r"<title\b[^>]*>\s*(.*?)\s*</title\s*>", text, re.I | re.S)
        description = attribute(text, "meta", "name", "description")
        canonical = attribute(text, "link", "rel", "canonical")
        og = [
            attribute(text, "meta", "property", name)
            for name in ("og:title", "og:description", "og:url", "og:image")
        ]
        twitter = [
            attribute(text, "meta", "name", name)
            for name in (
                "twitter:card",
                "twitter:title",
                "twitter:description",
                "twitter:image",
            )
        ]
        og_image = attribute(text, "meta", "property", "og:image")
        twitter_image = attribute(text, "meta", "name", "twitter:image")
        og_url = attribute(text, "meta", "property", "og:url")
        expected_canonical = canonical_url(base_url, relative)
        missing = []
        if not title or not re.sub(r"<[^>]+>", "", title.group(1)).strip():
            missing.append("title")
        if not description:
            missing.append("description")
        if not canonical:
            missing.append("canonical")
        elif href(canonical) != expected_canonical:
            missing.append(f"canonical={expected_canonical}")
        if not og_url or content(og_url) != expected_canonical:
            missing.append(f"og:url={expected_canonical}")
        if not all(og) or not all(content(tag) for tag in og if tag):
            missing.append("Open Graph tags")
        if not all(twitter) or not all(content(tag) for tag in twitter if tag):
            missing.append("Twitter tags")
        if not og_image or content(og_image) != SOCIAL_IMAGE:
            missing.append(f"og:image={SOCIAL_IMAGE}")
        if not twitter_image or content(twitter_image) != SOCIAL_IMAGE:
            missing.append(f"twitter:image={SOCIAL_IMAGE}")
        if DOI not in text or '"SoftwareApplication"' not in text or '"SoftwareSourceCode"' not in text:
            missing.append("structured data")
        if missing:
            errors.append(f"{relative}: missing {', '.join(missing)}")
            continue
        title_value = html.unescape(re.sub(r"<[^>]+>", "", title.group(1))).strip()
        description_value = re.search(
            r'\bcontent\s*=\s*["\']([^"\']+)', description.group(0), re.I
        )
        description_value = (
            html.unescape(description_value.group(1)).strip()
            if description_value
            else ""
        )
        titles.setdefault(title_value, []).append(relative)
        descriptions.setdefault(description_value, []).append(relative)

    for label, values in (("title", titles), ("description", descriptions)):
        for value, paths in values.items():
            if not value:
                errors.append(f"{paths[0]}: empty {label}")
            elif len(paths) > 1:
                errors.append(
                    f"duplicate {label} on " + ", ".join(str(path) for path in paths)
                )
    if not (root / "sitemap.xml").is_file():
        errors.append("missing sitemap.xml")
    robots = root / "robots.txt"
    if not robots.is_file():
        errors.append("missing robots.txt")
    else:
        robots_text = robots.read_text(encoding="utf-8")
        if not re.search(
            r"^Sitemap: https://julia\.dseams\.info/(?:[^/\s]+/)?sitemap\.xml$",
            robots_text,
            re.M,
        ):
            errors.append("robots.txt has no custom-domain sitemap")
    index = root / "index.html"
    if index.is_file():
        index_text = index.read_text(encoding="utf-8", errors="replace")
        if len(index_text.encode("utf-8")) < 1000:
            errors.append("root index.html is an empty deployment shell")
        if re.search(r"<meta\b[^>]*http-equiv\s*=\s*['\"]?refresh", index_text, re.I):
            errors.append("root index.html is a meta-refresh deployment shell")
    if errors:
        raise ValueError("\n".join(errors))
    print(f"Search metadata ok ({len(pages)} HTML pages)")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("apply", "check"))
    parser.add_argument("root", type=Path)
    parser.add_argument("--base-url", default="https://julia.dseams.info/")
    args = parser.parse_args()
    try:
        if args.command == "apply":
            apply(args.root, args.base_url)
        else:
            check(args.root, args.base_url)
    except ValueError as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
