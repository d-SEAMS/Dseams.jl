# API

`Dseams` has two layers:

1. Frame-level analysis functions (`read_frame`, `chill_plus`,
   `primitive_rings`, `cages`, `steinhardt`, `q4_q6`, `symmetry`,
   `jump_tau90`) that operate on trajectory frames.
2. Re-exported `seams_*` wrappers for lower-level tasks that map closely
   to the C ABI.

Common starting points:

- `read_frame(path; kwargs...)` to load one frame.
- `nframes(path)` to inspect trajectory length before analysis.
- `Dseams.example_path(name)` for bundled demonstration trajectories.

The full exported API is listed below.

```@autodocs
Modules = [Dseams]
```
