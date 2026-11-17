# Rewrites a built Documenter site so it needs no CDN and carries the d-SEAMS look.
#   include("postprocess.jl"); dseams_postprocess(joinpath(@__DIR__, "build"), @__DIR__)
const VENDOR = "assets/dseams/vendor"

const CDN_MODULES = Dict(
    "https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.13.2/jquery-ui.min" => "dseams/vendor/jquery-ui.min",
    "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/languages/julia.min" => "dseams/vendor/languages/julia.min",
    "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.7.0/jquery.min" => "dseams/vendor/jquery.min",
    "https://cdnjs.cloudflare.com/ajax/libs/headroom/0.12.0/headroom.min" => "dseams/vendor/headroom.min",
    "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/highlight.min" => "dseams/vendor/highlight.min",
    "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.16.8/contrib/auto-render.min" => "dseams/vendor/contrib/auto-render.min",
    "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.16.8/katex.min" => "dseams/vendor/katex.min",
    "https://cdnjs.cloudflare.com/ajax/libs/headroom/0.12.0/jQuery.headroom.min" => "dseams/vendor/jQuery.headroom.min",
    "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.8.0/languages/julia-repl.min" => "dseams/vendor/languages/julia-repl.min",
)

const CSS_LINKS = Dict(
    "font-awesome/6.4.2/css/fontawesome.min.css" => "fontawesome.min.css",
    "font-awesome/6.4.2/css/solid.min.css" => "solid.min.css",
    "font-awesome/6.4.2/css/brands.min.css" => "brands.min.css",
    "KaTeX/0.16.8/katex.min.css" => "katex.min.css",
)

function patch_documenter_js(text)
    for (cdn, local_path) in CDN_MODULES
        text = replace(text, cdn => local_path)
    end
    text = replace(text, "https://cdnjs.cloudflare.com/ajax/libs/minisearch/6.2.0/umd/index.min.js" => "__DSEAMS_MINISEARCH__")
    text = replace(
        text,
        "worker_function.toString() +" =>
            "worker_function.toString().replace(\"__DSEAMS_MINISEARCH__\", new URL(documenterBaseURL + \"/$(VENDOR)/minisearch.min.js\", window.location.href).href) +",
    )
    return text
end

function patch_page(text, family)
    m = match(r"documenterBaseURL=\"([^\"]*)\"", text)
    base = m === nothing ? "." : m.captures[1]
    asset(p) = string(base, "/", VENDOR, "/", p)
    text = replace(text, r"<link href=\"https://cdnjs\.cloudflare\.com/ajax/libs/(?:lato-font|juliamono)/[^\"]*\"[^>]*/>" => "")
    for (frag, file) in CSS_LINKS
        text = replace(
            text,
            Regex("<link href=\"https://cdnjs\\.cloudflare\\.com/ajax/libs/" * replace(frag, "." => "\\.") * "\"([^>]*)/>") =>
                SubstitutionString("<link href=\"" * asset(file) * "\"\\1/>"),
        )
    end
    text = replace(
        text,
        r"<script src=\"https://cdnjs\.cloudflare\.com/ajax/libs/require\.js/[^\"]*\"" =>
            SubstitutionString("<script src=\"" * asset("require.min.js") * "\""),
    )
    text = replace(text, r"<script data-outdated-warner[^>]*></script>" => "")
    text = replace(text, r"<script src=\"siteinfo\.js\"></script>" => "")
    text = replace(text, r"<script src=\"(?:\.\./)*versions\.js\"></script>" => "")
    text = replace(text, r"<link class=\"docs-theme-link\"[^>]*catppuccin[^>]*/>" => "")
    text = replace(text, r"<option value=\"catppuccin[^>]*>[^<]*</option>" => "")
    text = replace(text, "<option value=\"documenter-light\">documenter-light</option>" => "<option value=\"documenter-light\">Light</option>")
    text = replace(text, "<option value=\"documenter-dark\">documenter-dark</option>" => "<option value=\"documenter-dark\">Dark</option>")
    text = replace(text, r"<hr/><p>This document was generated with .*?</p>" => "")
    text = replace(text, r"<div class=\"docs-version-selector.*?</select></div></div></div>" => "")
    text = replace(text, "<body>" => "<body>" * family; count = 1)
    # Documenter lists custom css before its themes; the cascade needs ours last.
    mine = string(
        "<link href=\"", base, "/assets/dseams/dseams-tokens.css\" rel=\"stylesheet\" type=\"text/css\"/>",
        "<link href=\"", base, "/assets/dseams/dseams-family.css\" rel=\"stylesheet\" type=\"text/css\"/>",
        "<link href=\"", base, "/assets/dseams/dseams-documenter.css\" rel=\"stylesheet\" type=\"text/css\"/>",
    )
    text = replace(text, r"<link href=\"[^\"]*assets/dseams/dseams-(?:tokens|family|documenter)\.css\"[^>]*/>" => "")
    text = replace(text, "</head>" => mine * "</head>"; count = 1)
    icons = string(
        "<link rel=\"icon\" href=\"", base, "/assets/dseams/favicon.svg\" type=\"image/svg+xml\"/>",
        "<link rel=\"icon\" href=\"", base, "/assets/dseams/favicon-32.png\" sizes=\"32x32\" type=\"image/png\"/>",
        "<link rel=\"apple-touch-icon\" href=\"", base, "/assets/dseams/apple-touch-icon.png\"/>",
    )
    return replace(text, "</head>" => icons * "</head>"; count = 1)
end

function dseams_postprocess(build, docsdir)
    family = read(joinpath(docsdir, "dseams-family.html"), String)
    for (root, _, files) in walkdir(build), file in files
        path = joinpath(root, file)
        if endswith(file, ".html")
            write(path, patch_page(read(path, String), family))
        elseif file == "documenter.js"
            write(path, patch_documenter_js(read(path, String)))
        end
    end
    for stale in ("versions.js", "siteinfo.js")
        rm(joinpath(build, stale); force = true)
    end
    rm(joinpath(build, "assets", "warner.js"); force = true)
    for theme in readdir(joinpath(build, "assets", "themes"))
        startswith(theme, "catppuccin") && rm(joinpath(build, "assets", "themes", theme))
    end
end
