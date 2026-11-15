# Examples

The scripts in `examples/` run in the test suite: `test/examples.jl`
starts each one in its own process and checks its exit status and the
line it prints. `lang_tasks.jl` and `julia_api.jl` read the frames in
`data/`. The others read seams-core's `input/traj` and run when
`DSEAMS_ROOT` names a seams-core checkout.

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

```@eval
import Markdown, Dseams
Markdown.parse("```julia\n" * read(joinpath(pkgdir(Dseams), "examples", "julia_api.jl"), String) * "```")
```

## Ice Ih and sII census

```@eval
import Markdown, Dseams
Markdown.parse("```julia\n" * read(joinpath(pkgdir(Dseams), "examples", "core_counts.jl"), String) * "```")
```

## The GenIce sI cell

```@eval
import Markdown, Dseams
Markdown.parse("```julia\n" * read(joinpath(pkgdir(Dseams), "examples", "minimal_julia.jl"), String) * "```")
```

## Science tutorials on the C API

The interface and nucleus layer stacks and the clathrate cage counts,
called through `libseams` with `ccall` and no package beyond `Libdl`.

```@eval
import Markdown, Dseams
Markdown.parse("```julia\n" * read(joinpath(pkgdir(Dseams), "examples", "science_tutorials.jl"), String) * "```")
```
