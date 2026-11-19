# Getting started

The commands on this page are the same path used in CI: build
`seams-core`, point `Dseams` at that build, then run a quick analysis.

## 1. Build the engine

Set `CORE` to your local `seams-core` checkout and build the shared
libraries used by the Julia front.

```bash
export CORE=/path/to/seams-core
cd "$CORE"
pixi run meson setup bbdir -Dwith_tests=true -Dwith_cli=true
pixi run ninja -C bbdir bindings/libseams_lang.so bindings/binding_oracle src/libseams.so
```

## 2. Prepare Dseams.jl

Clone this repository and set up the stand-in `libseams_jll` package for
the project environment.

```bash
git clone https://github.com/d-SEAMS/Dseams.jl
cd Dseams.jl
julia --project=. dev/develop_jll.jl
```

## 3. Export runtime library paths

```bash
export SEAMS_LANG_LIB="$CORE/bbdir/bindings/libseams_lang.so"
export SEAMS_LIB="$CORE/bbdir/src/libseams.so"
export SEAMS_CPP_ORACLE="$CORE/bbdir/bindings/binding_oracle"
export SEAMS_SOURCE_ROOT="$CORE"
export DSEAMS_ROOT="$CORE"
```

## 4. Run a smoke test

```bash
julia --project=. -e 'using Dseams; f=read_frame(Dseams.ice_ih_path(); type=-1); println(chill_plus(f; graph="cutoff").counts["hexagonal"])'
```

Expected output:

```text
128
```

## 5. Run tests and docs

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
```

## 6. Check optional readers

Native LAMMPS dumps and XYZ files are always supported. Check whether the loaded engine also includes chemfiles (PDB, GRO, DCD, CIF) and `readcon-core` (`.con`):

```julia
using Dseams
features()       # (chemfiles = ..., readcon = ...)
has_chemfiles()  # true when chemfiles readers are available
has_readcon()    # true when readcon-core (.con) is available
```
