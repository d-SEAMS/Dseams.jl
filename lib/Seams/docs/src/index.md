# Seams

`Seams` is a compact Julia example around the stable C API in
`seams-core/include/seams.h` (`libseams`). The package shows the direct
`ccall` layer in `lib/Seams/src/capi.jl`, which `Dseams` also carries and
re-exports.

`SEAMS_LIB` names `libseams.so` from a seams-core build (`build/src`)
when it is not on the loader path.

Quick run, reading seams-core's own ice Ih trajectory:

```bash
export CORE=/path/to/seams-core
export SEAMS_LIB="$CORE/bbdir/src/libseams.so"
julia --project=lib/Seams -e '
using Pkg; Pkg.instantiate(); using Seams
sys = System()
seams_system_read(sys, ARGS[1])
println(six_rings(sys).count)
' "$CORE/input/traj/ice1h.lammpstrj"
```

Expected output:

```text
256
```

For a frame-front comparison, Ice Ih has 128 hexagonal waters and
256 primitive six-rings. `Dseams.chill_plus` and `Dseams.primitive_rings`
assert both.

```@autodocs
Modules = [Seams]
```
