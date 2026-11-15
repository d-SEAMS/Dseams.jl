# Copyright (c) d-SEAMS developers
# Read the GenIce sI cell: neighbours via steinhardt, then q6, CHILL+, rings.
#
#   julia --project=. examples/minimal_julia.jl /path/to/seams-core/input/traj/genice_sI.lammpstrj
#
# With no argument the cell is read from DSEAMS_ROOT.
using Dseams

mean(values) = sum(values) / length(values)

path = isempty(ARGS) ? joinpath(ENV["DSEAMS_ROOT"], "input", "traj", "genice_sI.lammpstrj") : ARGS[1]
frame = read_frame(path)
@assert nop(frame) == 46
order = steinhardt(frame, 6; cutoff = 3.5)
@assert length(order.ql) == 46
@assert mean(order.ql) > 0.5
ice = chill_plus(frame)
@assert ice.counts["clathrate"] == 46
rings = primitive_rings(frame; graph = "cutoff")
@assert rings[5] == 48
@assert rings[6] == 54
println("julia example ok")
