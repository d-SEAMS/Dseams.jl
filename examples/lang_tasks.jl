# Copyright (c) d-SEAMS developers
# Neighbours, rings, and CHILL+ from Julia on the ice Ih cell in data/.
# The line it prints is the one every seams-core language example prints:
#   pairs 512 rings 0 0 0 0 0 0 256 chill 0 128 0 0 0 0 0 0 0
#
#   julia --project=. examples/lang_tasks.jl
using Dseams

const labels = (
    "cubic",
    "hexagonal",
    "water",
    "interfacial",
    "clathrate",
    "interClathrate",
    "unclassified",
    "reCubic",
    "reHex",
)

frame = read_frame(Dseams.ice_ih_path(); type = -1)
pairs = neighbour_pairs(frame; cutoff = 3.5, graph = "cutoff")
rings = primitive_rings(frame; cutoff = 3.5, graph = "cutoff", max_depth = 6)
histogram = [get(rings.counts, size, 0) for size in 0:6]
ice = chill_plus(frame; cutoff = 3.5, graph = "cutoff")
counts = [ice.counts[name] for name in labels]
println(
    "pairs ",
    pairs,
    " rings ",
    join(histogram, " "),
    " chill ",
    join(counts, " "),
)
