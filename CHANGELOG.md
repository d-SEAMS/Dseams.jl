# Changelog

All notable changes to Dseams.jl are documented in this file.

The format is [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the version follows the d-SEAMS engine release in `libseams_jll`.

Unreleased notes live in [`docs/newsfragments/`](docs/newsfragments/) and are
assembled by [towncrier](https://towncrier.readthedocs.io/).

<!-- towncrier release notes start -->

## [2.14.2] - 2026-11-24

[2.14.2]: https://github.com/d-SEAMS/Dseams.jl/tree/v2.14.2

### Added

- Public feature-query functions (`features()`, `has_chemfiles()`, and `has_readcon()`) reporting whether the loaded `libseams_lang` engine supports chemfiles (PDB, GRO, DCD, CIF) and `readcon-core` (`.con`), plus feature-gated `.con`, PDB, and GRO reader tests.
- Tests for empty frames across the public API: a frame with no atoms, a frame of atoms of no kept species, and a frame with atoms and no neighbour inside the cutoff, for Dseams and for the `seams_*` calls.

### Developer

- Org-mode developer guides (`docs/orgmode/contributing/developer/`) and release automation with cocogitto (`cog.toml`), towncrier (`towncrier.toml`), and cogapp (`ci/version/files.txt`).

### Changed

- Dseams builds and tests against seams-core 2.14.2 and pins libseams_jll to the matching engine version.
- The docstrings state what an empty frame gives from each analysis, and that the `"mutual"` graph is the four nearest neighbours with no bound from `cutoff + 1.5`, which only sizes the search cells.

### Fixed

- Indexing a `RingHistogram` with a size that has no ring returns 0 in place of throwing `KeyError`, so a frame with no atoms or no ring of that size gives a count.
- The Dseams manual now states that the Yggdrasil recipe is pinned to the seams-core commit `c1efa8c`, and no longer describes package release status.
- The Dseams manual's "The engine library" section, on `libseams_jll`, `Dseams.set_library!`, `LocalPreferences.toml`, `SEAMS_LANG_LIB`, and `Overrides.toml`, is restored after being dropped from the reader rewrite.
- The Seams quick-run example reads a trajectory into a `System` and calls `six_rings(sys).count`, in place of the no-argument `six_rings()` call that `six_rings` does not accept.
- The getting-started smoke test no longer escapes `"` inside a single-quoted shell string, which Julia read as a `ParseError`.
- `llms.txt` links to the manual at the site root, the same base the sitemap and `robots.txt` use.
- `llms.txt` lists the getting-started page.
- `read_frame` throws `SeamsError` for a frame below 1 or past the last frame of the file, and for chemfiles-only formats (such as PDB and GRO) when the loaded engine was built without chemfiles.
- `steinhardt` throws `SeamsError` for a degree other than 3, 4, 6, 8, or 12.


## [2.14.0] - 2026-11-17

### Changed

- Dseams.jl is its own repository. Dseams is at the root, Seams is under
  `lib/Seams`, and CI builds seams-core at tag `v2.14.0`. Earlier
  history is in [d-SEAMS/seams-core](https://github.com/d-SEAMS/seams-core)
  under `bindings/julia`.
- The Julia examples from seams-core `docs/examples` are in `examples/`;
  the tests run them and the manual shows them.
- Seams declares `julia = "1.10"`, the oldest Julia that CI tests, in
  place of 1.9.
