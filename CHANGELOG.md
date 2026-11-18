# Changelog

All notable changes to Dseams.jl are documented in this file.

The format is [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the version follows the d-SEAMS engine release in `libseams_jll`.

## [Unreleased]

### Fixed

- `llms.txt` links to the manual at the site root, the same base the
  sitemap and `robots.txt` use.

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
