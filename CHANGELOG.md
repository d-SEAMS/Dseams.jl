# Changelog

All notable changes to Dseams.jl are documented in this file.

The format is [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the version follows the d-SEAMS engine release in `libseams_jll`.

## [Unreleased]

### Added

- Tests for empty frames across the public API: a frame with no atoms,
  a frame of atoms of no kept species, and a frame with atoms and no
  neighbour inside the cutoff, for Dseams and for the `seams_*` calls.

### Changed

- The docstrings state what an empty frame gives from each analysis, and
  that the `"mutual"` graph is the four nearest neighbours with no bound
  from `cutoff + 1.5`, which only sizes the search cells. They said it
  keeps the neighbours inside `cutoff + 1.5`.

### Fixed

- `read_frame` throws `SeamsError` for a frame below 1 or past the last
  frame of the file. The engine answered both with a frame of no atoms.
- `steinhardt` throws `SeamsError` for a degree other than 3, 4, 6, 8, or
  12. The engine answered one with a vector of zeros.
- Indexing a `RingHistogram` with a size that has no ring returns 0 in
  place of throwing `KeyError`, so a frame with no atoms or no ring of
  that size gives a count.
- `llms.txt` links to the manual at the site root, the same base the
  sitemap and `robots.txt` use.
- The getting-started smoke test no longer escapes `"` inside a
  single-quoted shell string, which Julia read as a `ParseError`.

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
