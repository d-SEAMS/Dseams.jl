# Copyright (c) d-SEAMS developers
# Build the Dseams manual and run every doctest.
#
#   SEAMS_LANG_LIB=/path/to/build/bindings/libseams_lang.so \
#       julia --project=docs docs/make.jl
#
# The doctests call the engine, so SEAMS_LANG_LIB (or the libseams_lang
# preference) names a seams-core build until libseams_jll is registered.
using Pkg

docsdir = @__DIR__
Pkg.activate(docsdir)
# libseams_jll is not in General. Develop the checkout stand-in, which
# has no binaries, so Dseams opens SEAMS_LANG_LIB instead of a registry
# artifact. Relative paths keep the tracked project free of [sources].
proj = Pkg.project().path
cd(docsdir) do
    Pkg.develop([
        PackageSpec(; path = relpath(joinpath(docsdir, "..", "dev", "libseams_jll"), docsdir)),
        PackageSpec(; path = relpath(joinpath(docsdir, ".."), docsdir)),
    ])
    Pkg.instantiate()
end
text = read(proj, String)
stripped = replace(text, r"^\[sources\]\n(?:[^\[\n].*\n|\n)*"m => "")
stripped == text || write(proj, stripped)

using Documenter
using Dseams

DocMeta.setdocmeta!(Dseams, :DocTestSetup, :(using Dseams); recursive = true)

# Source links go to the file on main, with no line fragment: GitHub's
# static page has no id for #Lnn, so the link checker rejects it.
struct PublishedRemote <: Documenter.Remotes.Remote end
Documenter.Remotes.repourl(::PublishedRemote) = "https://github.com/d-SEAMS/Dseams.jl"
function Documenter.Remotes.fileurl(::PublishedRemote, ::AbstractString, filename::AbstractString, linerange)
    filename = lstrip(replace(filename, '\\' => '/'), '/')
    return "https://github.com/d-SEAMS/Dseams.jl/blob/main/$(filename)"
end

makedocs(;
    sitename = "Dseams",
    modules = [Dseams],
    checkdocs = :exports,
    doctest = true,
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", "") == "true", edit_link = "main"),
    repo = PublishedRemote(),
    pages = ["Home" => "index.md", "Examples" => "examples.md", "API" => "api.md"],
)
