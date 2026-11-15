# Seams

Seams is an example of the stable C API in seams-core's `include/seams.h`
(`libseams`): the ccall layer in `lib/Seams/src/capi.jl`, which Dseams
also carries and re-exports. It is not registered. The Julia package to
install is Dseams (the root of this repository), which reads trajectories
and covers the analyses of the R package.

`SEAMS_LIB` names `libseams.so` from a seams-core build (`build/src`)
when it is not on the loader path.

Ice Ih through the frame front is 128 hexagonal waters and 256 primitive
six-rings. `Dseams.chill_plus` and `Dseams.primitive_rings` assert both.
`six_rings` returns that six-ring count.

```@autodocs
Modules = [Seams]
```
