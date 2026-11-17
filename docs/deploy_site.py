#!/usr/bin/env python3
"""Stage Documenter output without replacing the custom-domain root by a redirect.

Documenter's versioned deploy writes a redirect at the branch root, while its
unversioned deploy replaces the root and removes version directories. This
promotes main in place using a manifest and updates tags in isolated folders.
"""

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

import seo

MANIFEST = ".dseams-root-files.json"
CNAME = "julia.dseams.info"


def fail(message):
    raise ValueError(message)


def source_files(source):
    return sorted(
        path.relative_to(source).as_posix()
        for path in source.rglob("*")
        if path.is_file()
    )


def remove_file(root, relative):
    relative_path = Path(relative)
    if relative_path.is_absolute() or ".." in relative_path.parts:
        fail(f"unsafe root manifest entry: {relative}")
    path = root / relative
    if path.is_file() or path.is_symlink():
        path.unlink()
    parent = path.parent
    while parent != root:
        try:
            parent.rmdir()
        except OSError:
            break
        parent = parent.parent


def copy_tree(source, destination):
    destination.mkdir(parents=True, exist_ok=True)
    for path in source.rglob("*"):
        relative = path.relative_to(source)
        target = destination / relative
        if path.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        elif path.is_file():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)


def validate_site(root, base_url):
    seo.check(root, base_url)
    index = root / "index.html"
    if not index.is_file():
        fail(f"{root} has no index.html")
    text = index.read_text(encoding="utf-8", errors="replace")
    if len(text.encode("utf-8")) < 1000:
        fail(f"{index} is an empty deployment shell")
    if re.search(r"<meta\b[^>]*http-equiv\s*=\s*['\"]?refresh", text, re.I):
        fail(f"{index} is a meta-refresh deployment shell")
    canonical = re.search(
        r"<link\b(?=[^>]*\brel\s*=\s*['\"]canonical['\"])[^>]*>",
        text,
        re.I,
    )
    if not canonical or f'href="{base_url}"' not in canonical.group(0):
        fail(f"{index} does not canonically identify {base_url}")
    robots = root / "robots.txt"
    expected = f"Sitemap: {base_url}sitemap.xml"
    if not robots.is_file() or expected not in robots.read_text(encoding="utf-8"):
        fail(f"{root} has no {expected} robots directive")


def validate_deployment(root):
    manifest = root / MANIFEST
    if not manifest.is_file():
        fail(f"{root} has no root file manifest")
    entries = json.loads(manifest.read_text(encoding="utf-8"))
    root_pages = [
        root / entry for entry in entries if Path(entry).suffix.lower() == ".html"
    ]
    seo.check(root, f"https://{CNAME}/", root_pages)
    checked = set(root_pages)
    for path in root.iterdir():
        if path.is_dir() and re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", path.name):
            pages = sorted(path.rglob("*.html"))
            seo.check(path, f"https://{CNAME}/{path.name}/", pages)
            checked.update(pages)
    all_pages = set(root.rglob("*.html"))
    if checked != all_pages:
        missed = ", ".join(
            path.relative_to(root).as_posix() for path in sorted(all_pages - checked)
        )
        fail(f"unvalidated HTML pages: {missed}")


def deploy_root(source, destination):
    base_url = f"https://{CNAME}/"
    validate_site(source, base_url)
    manifest = destination / MANIFEST
    if manifest.is_file():
        entries = json.loads(manifest.read_text(encoding="utf-8"))
        if not isinstance(entries, list) or not all(
            isinstance(entry, str) for entry in entries
        ):
            fail(f"{manifest} is invalid")
        for entry in entries:
            remove_file(destination, entry)

    versions = destination / "versions.js"
    if versions.is_file() or versions.is_symlink():
        versions.unlink()
    copy_tree(source, destination)

    dev = destination / "dev"
    if dev.exists() or dev.is_symlink():
        if dev.is_symlink() or dev.is_file():
            dev.unlink()
        else:
            shutil.rmtree(dev)

    manifest.write_text(
        json.dumps(source_files(source), indent=2) + "\n", encoding="utf-8"
    )
    (destination / "CNAME").write_text(CNAME + "\n", encoding="utf-8")
    validate_deployment(destination)


def deploy_tag(source, destination, version):
    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", version):
        fail(f"invalid documentation version: {version}")
    base_url = f"https://{CNAME}/{version}/"
    validate_site(source, base_url)
    target = destination / version
    if target.exists() or target.is_symlink():
        if target.is_symlink() or target.is_file():
            target.unlink()
        else:
            shutil.rmtree(target)
    copy_tree(source, target)
    (destination / "CNAME").write_text(CNAME + "\n", encoding="utf-8")
    validate_site(target, base_url)
    if (destination / "index.html").is_file():
        validate_deployment(destination)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--root", action="store_true")
    mode.add_argument("--version")
    args = parser.parse_args()
    try:
        if not (args.source / "index.html").is_file():
            fail(f"{args.source} is not built Documenter output")
        args.destination.mkdir(parents=True, exist_ok=True)
        if args.root:
            deploy_root(args.source, args.destination)
        else:
            deploy_tag(args.source, args.destination, args.version)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
