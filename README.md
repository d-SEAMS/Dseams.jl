# Dseams

Julia front for the [d-SEAMS](https://docs.dseams.info) engine: CHILL+,
primitive rings, ice cages, Steinhardt parameters and shell symmetry on
LAMMPS trajectories. The engine comes from `libseams_jll`, built from
[seams-core](https://github.com/d-SEAMS/seams-core).

```julia
using Dseams
f = read_frame(Dseams.ice_ih_path(); type = -1)
chill_plus(f; graph = "cutoff").counts["hexagonal"]   # 128
```

## A local engine build

Dseams and `libseams_jll` are not in the General registry yet. Until they
are, develop the stand-in JLL (it has no binaries) and name the
`libseams_lang` of a seams-core build (`ninja -C build
bindings/libseams_lang.so src/libseams.so` in a configured seams-core
checkout):

```sh
export SEAMS_LANG_LIB=/path/to/seams-core/build/bindings/libseams_lang.so
export SEAMS_LIB=/path/to/seams-core/build/src/libseams.so
julia --project=. dev/develop_jll.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

`SEAMS_LANG_LIB` takes precedence over the `libseams_lang` preference
that `Dseams.set_library!` writes, and either one keeps `libseams_jll`
from loading. `SEAMS_LIB` is the `libseams` (`include/seams.h`) behind
the re-exported `seams_*` calls.

Two more settings turn on checks against a seams-core checkout:
`DSEAMS_ROOT` (the larger trajectories in `input/traj`), and
`SEAMS_CPP_ORACLE` with `SEAMS_SOURCE_ROOT` (the `binding_oracle` program
in `build/bindings` compares the `seams.h` calls with the C++ census).
`.github/workflows/CI.yml` sets all of them.

## Layout

| Path | Contents |
|---|---|
| `Project.toml`, `src/`, `test/`, `data/` | Dseams, the registered package |
| `docs/` | Dseams manual (`julia --project=docs docs/make.jl`), published with `llms.txt` |
| `examples/` | Scripts from the seams-core docs; `test/examples.jl` runs them |
| `dev/` | `develop_jll.jl` and the stand-in `libseams_jll` |
| `lib/Seams/` | Seams, an unregistered example of the `libseams` C API |

`src/capi.jl` and `lib/Seams/src/capi.jl` are the same file, as are the
two `test/cpp_match.jl`; the Dseams tests fail when they differ.

## Development

Dseams.jl holds only Julia code. The engine, its C API (`include/seams.h`)
and the C ABI that Dseams calls (`bindings/cxx/seams_lang.h`) are in
[d-SEAMS/seams-core](https://github.com/d-SEAMS/seams-core), together
with the Yggdrasil recipe for `libseams_jll`. A change to analysis
results goes there first; this repository then moves to the released
engine. The contributing guide at the repository root has the
conventions, and `CHANGELOG.md` the changes by release.

To work against a local seams-core checkout, build its libraries and
point the package at them:

```sh
cd /path/to/seams-core
meson setup bbdir
ninja -C bbdir bindings/libseams_lang.so bindings/binding_oracle src/libseams.so

cd /path/to/Dseams.jl
CORE=/path/to/seams-core
export SEAMS_LANG_LIB=$CORE/bbdir/bindings/libseams_lang.so
export SEAMS_LIB=$CORE/bbdir/src/libseams.so
export DSEAMS_ROOT=$CORE SEAMS_SOURCE_ROOT=$CORE
export SEAMS_CPP_ORACLE=$CORE/bbdir/bindings/binding_oracle
julia --project=. dev/develop_jll.jl
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
```

CI does the same against seams-core tag `v2.14.0`, pinned as
`SEAMS_CORE_REF` in `.github/workflows/CI.yml`.

## Release order

1. seams-core tags the engine release (`v2.14.0`).
2. `libseams_jll` of that version is registered in General from the
   Yggdrasil recipe.
3. `SEAMS_CORE_REF` moves to that tag, `Project.toml` carries the same
   version with `libseams_jll = "=2.14.0"`, and CI is green on `main`.
4. The `Register Dseams` workflow asks JuliaRegistrator to register that
   commit. TagBot tags `vX.Y.Z` once General merges it, and the tag
   publishes that version of the manual.

Dseams cannot be registered before step 2: General refuses a package
whose `[compat]` names an unregistered dependency.
