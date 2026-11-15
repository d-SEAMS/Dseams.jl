# Copyright (c) d-SEAMS developers
# Build the Seams manual and run every export's doctest.
#
#   SEAMS_LIB=/path/to/build/src/libseams.so \
#       julia --project=lib/Seams/docs lib/Seams/docs/make.jl
using Pkg

docsdir = @__DIR__
Pkg.activate(docsdir)
proj = Pkg.project().path
cd(docsdir) do
    Pkg.develop(PackageSpec(; path = relpath(joinpath(docsdir, ".."), docsdir)))
    Pkg.instantiate()
end
text = read(proj, String)
stripped = replace(text, r"^\[sources\]\n(?:[^\[\n].*\n|\n)*"m => "")
stripped == text || write(proj, stripped)

using Documenter
using Seams

# GitHub's static page has no id for a #Lnn fragment, so a line link fails
# the HTML checker. A commit that has not been pushed 404s as well. The
# published file is the one on main. Paths are relative to the repository
# root, so Seams files sit under lib/Seams.
struct PublishedRemote <: Documenter.Remotes.Remote end
Documenter.Remotes.repourl(::PublishedRemote) = "https://github.com/d-SEAMS/Dseams.jl"
function Documenter.Remotes.fileurl(::PublishedRemote, ::AbstractString, filename::AbstractString, linerange)
    filename = lstrip(replace(filename, '\\' => '/'), '/')
    return "https://github.com/d-SEAMS/Dseams.jl/blob/main/$(filename)"
end

makedocs(;
    sitename = "Seams",
    modules = [Seams],
    checkdocs = :exports,
    doctest = true,
    format = Documenter.HTML(; edit_link = "main"),
    repo = PublishedRemote(),
    pages = ["index.md"],
)
