# Contributing to Dseams.jl

Dseams.jl is the Julia front for the d-SEAMS engine. The engine, its C
API and its C ABI live in [d-SEAMS/seams-core](https://github.com/d-SEAMS/seams-core);
this repository holds only Julia code, example data, docs and CI.

## Layout

| Path | Contents |
|---|---|
| `Project.toml`, `src/` | Dseams, the registered package. `src/capi.jl` is the ccall layer over `seams.h` |
| `test/` | `runtests.jl`, `examples.jl` (runs `examples/`), `cpp_match.jl` (C++ oracle check) |
| `data/` | Small trajectories shipped with the package, with `.source.txt` provenance |
| `examples/` | Scripts that the tests run and the manual shows |
| `dev/` | `develop_jll.jl` and a stand-in `libseams_jll` with no binaries |
| `docs/` | Documenter manual; `llms.txt` is published with it |
| `lib/Seams/` | Seams, an unregistered example of the `libseams` C API |

`src/capi.jl` and `lib/Seams/src/capi.jl` are one file kept in two
places, as are `test/cpp_match.jl` and `lib/Seams/test/cpp_match.jl`.
Edit both copies in the same commit; the Dseams tests fail when they
differ.

## The engine

Dseams calls two libraries from seams-core:

- `libseams_lang` (`bindings/cxx/seams_lang.h`): every Dseams function.
  Found through `SEAMS_LANG_LIB`, then the `libseams_lang` preference
  (`Dseams.set_library!`), then `libseams_jll`.
- `libseams` (`include/seams.h`): the re-exported `seams_*` calls and
  Seams. Found through `SEAMS_LIB`, then the loader path.

`Project.toml` holds `libseams_jll` at the exact engine version
(`=2.14.2`), and the Dseams version matches it. The Yggdrasil recipe for
`libseams_jll` is in seams-core `packaging/yggdrasil`. Until the JLL is in
General, `julia --project=. dev/develop_jll.jl` develops the stand-in and
the engine is a local seams-core build.

CI builds seams-core at the tag pinned as `SEAMS_CORE_REF` in
`.github/workflows/CI.yml`. That pin is the seams-core release tag
`v2.14.2`, which matches `[compat] libseams_jll`.

A change to analysis results, the C API or the C ABI goes to seams-core,
with its tests there. This repository then follows the released engine:
bump `libseams_jll` compat, the version, and `SEAMS_CORE_REF` together.

## Build and test

There is nothing to compile here. With a seams-core build tree at `$CORE`
(`meson setup bbdir` then
`ninja -C bbdir bindings/libseams_lang.so bindings/binding_oracle src/libseams.so`):

```sh
export SEAMS_LANG_LIB=$CORE/bbdir/bindings/libseams_lang.so
export SEAMS_LIB=$CORE/bbdir/src/libseams.so
export DSEAMS_ROOT=$CORE                 # seams-core input/ data tests and examples
export SEAMS_SOURCE_ROOT=$CORE           # with the oracle: seams.h against C++
export SEAMS_CPP_ORACLE=$CORE/bbdir/bindings/binding_oracle
julia --project=. dev/develop_jll.jl
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=lib/Seams -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
julia --project=docs docs/make.jl
julia --project=lib/Seams/docs lib/Seams/docs/make.jl
```

Without the last three variables the tests that need seams-core data or
the oracle do not run; CI sets all of them. Do not remove, skip or loosen
a test to make a run pass; fix the code or the engine.

Every exported function has a docstring with a `jldoctest`
(`checkdocs = :exports`), and the manual build runs the doctests.

## Commits and changes

- Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `ci:`,
  `refactor:`, `chore:`, `style:`, with an optional scope
  (`fix(docs): ...`). One logical change per commit. Checked with
  `cog check --ignore-merge-commits <base>..HEAD` (`cog.toml`).
- ASCII punctuation in code, docs and commit messages.
- `CHANGELOG.md` is managed by [towncrier](https://towncrier.readthedocs.io/)
  (`towncrier.toml`). A user-visible change adds a fragment under
  `docs/newsfragments/` in the same commit instead of editing `CHANGELOG.md`
  directly. Preview with `towncrier build --draft`.

## Releases

The canonical step-by-step release guide is
[`docs/orgmode/contributing/developer/release.org`](docs/orgmode/contributing/developer/release.org)
(alongside `index.org`, `testing.org`, and `faq.org` in that directory).
Versions stay in lockstep with `Project.toml` via `cogapp`
(`ci/version/files.txt`) and `cog bump` (`cog.toml`, `tag_prefix = "v"`):

1. seams-core tags the engine release, and `libseams_jll` of that version
   is merged into General.
2. Run tests, docs builds, `cog check`, `python3 -m cogapp --check -I ci/version @ci/version/files.txt`,
   and `cog bump --version X.Y.Z` (see `docs/orgmode/contributing/developer/release.org`).
3. Push `main` (without pushing a pre-General tag ahead of TagBot), confirm CI
   (`test` and `both-libs`) is green, then run the `Register Dseams` workflow.
   TagBot tags `vX.Y.Z` after General merges the registration.
