# Copyright (c) d-SEAMS developers
# CHILL+ and q4/q6 on the TIP4P/ice frame shipped in data/.
#
#   julia --project=. examples/julia_api.jl
using Dseams

frame = read_frame(Dseams.example_path("exampleTraj.lammpstrj"); type = 2)
@assert nop(frame) == 250
ice = chill_plus(frame)
@assert ice.counts["interClathrate"] == 9
@assert ice.counts["water"] == 241
order = q4_q6(frame)
@assert length(order.q6) == nop(frame)
println("julia api ok")
