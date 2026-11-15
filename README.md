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
| `docs/` | Dseams manual (`julia --project=docs docs/make.jl`) |
| `examples/` | Scripts from the seams-core docs; `test/examples.jl` runs them |
| `dev/` | `develop_jll.jl` and the stand-in `libseams_jll` |
| `lib/Seams/` | Seams, an unregistered example of the `libseams` C API |

`src/capi.jl` and `lib/Seams/src/capi.jl` are the same file, as are the
two `test/cpp_match.jl`; the Dseams tests fail when they differ.

## Registering

`Project.toml` is ready for Registrator (`uuid`, `version`, and
`[compat]`, with `libseams_jll` held at `=2.14.0`). General can resolve
that dependency only after `libseams_jll` is registered from the
Yggdrasil recipe in seams-core's `packaging/yggdrasil`. The
`Register Dseams` workflow then asks JuliaRegistrator to register the
chosen commit, and TagBot tags the release `vX.Y.Z`.
