# Examples

All scripts in `examples/` are exercised by `test/examples.jl`. Each
script runs in its own process and the test checks both exit status and
printed output.

Run the scripts that only use bundled data:

```bash
julia --project=. examples/lang_tasks.jl
julia --project=. examples/julia_api.jl
```

Run the scripts that use trajectories from a `seams-core` checkout:

```bash
export DSEAMS_ROOT=/path/to/seams-core
julia --project=. examples/core_counts.jl
julia --project=. examples/minimal_julia.jl "$DSEAMS_ROOT/input/traj/genice_sI.lammpstrj"
julia --project=. examples/science_tutorials.jl "$DSEAMS_ROOT"
```

## Neighbours, rings and CHILL+

`neighbour_pairs`, `primitive_rings`, and `chill_plus` on ice Ih. The
ring dictionary omits empty sizes, so the printed histogram asks for each
size from 0 through 6. Every seams-core language example prints the same
line, `pairs 512 rings 0 0 0 0 0 0 256 chill 0 128 0 0 0 0 0 0 0`.

```@eval
import Markdown, Dseams
Markdown.parse("```julia\n" * read(joinpath(pkgdir(Dseams), "examples", "lang_tasks.jl"), String) * "```")
```

## CHILL+ and q4/q6 on the TIP4P/ice frame

Expected output: `julia api ok`.

```@eval
import Markdown, Dseams
Markdown.parse("```julia\n" * read(joinpath(pkgdir(Dseams), "examples", "julia_api.jl"), String) * "```")
```

## Ice Ih and sII census

Expected output:
`julia hexagonal 128 rings6 256 clathrate 136 rings5 144`.

```@eval
import Markdown, Dseams
Markdown.parse("```julia\n" * read(joinpath(pkgdir(Dseams), "examples", "core_counts.jl"), String) * "```")
```

## The GenIce sI cell

Expected output: `julia example ok`.

```@eval
import Markdown, Dseams
Markdown.parse("```julia\n" * read(joinpath(pkgdir(Dseams), "examples", "minimal_julia.jl"), String) * "```")
```

## Science tutorials on the C API

The interface and nucleus layer stacks and the clathrate cage counts,
called through `libseams` with `ccall` and no package beyond `Libdl`.

Expected output includes:

- `interface hexagonal 352 water 434 interfacial 49 cubic 1`
- `nucleus cubic 47 hexagonal 62 water 3589 interfacial 240`
- `cages sII 512 16`
- `cages sH 51268 4`

```@eval
import Markdown, Dseams
Markdown.parse("```julia\n" * read(joinpath(pkgdir(Dseams), "examples", "science_tutorials.jl"), String) * "```")
```
