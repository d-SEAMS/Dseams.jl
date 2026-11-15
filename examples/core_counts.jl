# Copyright (c) d-SEAMS developers
# Ice Ih and sII census through Dseams.
# Ice Ih: 128 hexagonal, 256 six-rings.
# sII: 136 clathrate, 144 five-rings, 16 six-rings.
#
#   DSEAMS_ROOT=/path/to/seams-core julia --project=. examples/core_counts.jl
#
# Ice Ih ships in data/; the sII cell is seams-core input/traj/genice_sII.lammpstrj.
using Dseams

function census(path)
    frame = read_frame(path)
    ice = chill_plus(frame; cutoff = 3.5, graph = "cutoff")
    rings = primitive_rings(frame; cutoff = 3.5, graph = "cutoff")
    ice, rings
end

root = get(ENV, "DSEAMS_ROOT", "")
@assert !isempty(root) "DSEAMS_ROOT names a seams-core checkout"
ice, ice_rings = census(Dseams.ice_ih_path())
@assert ice.counts["hexagonal"] == 128
@assert ice_rings[6] == 256
sii, sii_rings = census(joinpath(root, "input", "traj", "genice_sII.lammpstrj"))
@assert sii.counts["clathrate"] == 136
@assert sii_rings[5] == 144
@assert sii_rings[6] == 16
println("julia hexagonal 128 rings6 256 clathrate 136 rings5 144")
