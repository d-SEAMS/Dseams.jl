# Dseams

`Dseams.jl` is a Julia front for the [d-SEAMS](https://docs.dseams.info)
engine. It reads LAMMPS trajectories and exposes the same core analyses:
CHILL+, primitive rings, cage census, Steinhardt order, shell symmetry,
and jump reorientation times.

```julia
using Dseams
f = read_frame(Dseams.ice_ih_path(); type = -1)
chill_plus(f; graph = "cutoff").counts["hexagonal"]       # 128
primitive_rings(f; graph = "cutoff", max_depth = 6)[6]    # 256
```

The [Julia chapter](https://docs.dseams.info/stable/julia.html) of the
d-SEAMS book covers the same interface, and a
[video walk-through](https://odysee.com/dseams-julia:ec237bd28c57b7bdfa2996ccc420c16d9799176f)
shows a full session.

```@raw html
<iframe id="odysee-iframe" title="Dseams.jl walk-through" width="560" height="315" src="https://odysee.com/$/embed/dseams-julia:ec237bd28c57b7bdfa2996ccc420c16d9799176f" allowfullscreen></iframe>
```

## What to read next

- [Getting started](getting-started.md): build the engine, configure
  `Dseams`, and run a smoke test.
- [Examples](examples.md): runnable scripts and expected outputs.
- [API](api.md): function reference for frame analysis and lower-level
  wrappers.

This repository also includes `lib/Seams`, a compact example package
around the lower-level `libseams` C API.

## The engine library

`libseams_jll` provides the engine for Linux (glibc and musl; x86_64,
aarch64, powerpc64le, riscv64) and macOS once the recipe, pinned to
seams-core commit `c1efa8c`, is merged into Yggdrasil.
`dev/develop_jll.jl` develops a stand-in `libseams_jll` with no binaries,
and the engine is a local build of
[seams-core](https://github.com/d-SEAMS/seams-core). To use one, name its
`libseams_lang`:

```julia
Dseams.set_library!("/path/to/seams-core/bbdir/bindings/libseams_lang.so")
# restart Julia; Dseams.set_library!(nothing) goes back to the JLL
```

This writes the `libseams_lang` preference to `LocalPreferences.toml`.
The `SEAMS_LANG_LIB` environment variable takes precedence over the
preference. With either one set, `libseams_jll` is not loaded.

To replace the whole JLL artifact with an install prefix instead, use
an `Overrides.toml` in `~/.julia/artifacts`, as for any JLL.

## Data used in examples

`Dseams.example_path(name)` resolves the trajectories bundled in `data/`:
`ice1h.lammpstrj` (ice Ih, 128 oxygens), `exampleTraj.lammpstrj` (a
TIP4P/ice frame) and `nucleation_f1.lammpstrj` (one frame of an mW
nucleation run). The `.source.txt` files there record where they came
from.
