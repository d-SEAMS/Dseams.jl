# Copyright (c) d-SEAMS developers
# Empty frames across the public API: a frame with no atoms, a frame with
# atoms of no kept species (no molecules), and a frame with atoms but no
# neighbour inside the cutoff. Every call returns the typed empty result or
# throws SeamsError; none reads past an array or returns a frame that is
# empty only because the request was out of range.
#
# The mutual graph (also the default of primitive_rings and the seeded cage
# graph) is the four nearest neighbours with no distance bound, so a frame
# of isolated atoms is not empty for it. Those calls are held to the
# invariants of any graph: sizes, types, and counts that add up.

const NINE_LABELS = 9

function write_dump(path, frames; box = 30.0)
    open(path, "w") do io
        for (step, atoms) in enumerate(frames)
            println(io, "ITEM: TIMESTEP\n", step - 1, "\nITEM: NUMBER OF ATOMS\n", length(atoms))
            println(io, "ITEM: BOX BOUNDS pp pp pp")
            for _ in 1:3
                println(io, "0.0 ", box)
            end
            println(io, "ITEM: ATOMS id type x y z")
            for (id, (type, x, y, z)) in enumerate(atoms)
                println(io, id, " ", type, " ", x, " ", y, " ", z)
            end
        end
    end
    return path
end

const EMPTY_DIR = mktempdir()
const ZERO_PATH = write_dump(joinpath(EMPTY_DIR, "zero.lammpstrj"), [[]])
const ONE_PATH = write_dump(joinpath(EMPTY_DIR, "one.lammpstrj"), [[(1, 1.0, 1.0, 1.0)]])
# Pairwise minimum-image distance is at least 10 angstrom, well past the
# 3.5 cutoff and the 5.0 of cutoff + 1.5.
const ISOLATED_PATH = write_dump(
    joinpath(EMPTY_DIR, "isolated.lammpstrj"),
    [[(1, 1.0, 1.0, 1.0), (1, 11.0, 11.0, 11.0), (1, 21.0, 21.0, 21.0)]],
)
const ZERO_THEN_ONE_PATH = write_dump(
    joinpath(EMPTY_DIR, "zero_then_one.lammpstrj"),
    [[], [(1, 1.0, 1.0, 1.0)]];
    box = 10.0,
)
const BLANK_PATH = joinpath(EMPTY_DIR, "blank.lammpstrj")
write(BLANK_PATH, "")
const TRUNCATED_PATH = joinpath(EMPTY_DIR, "truncated.lammpstrj")
write(
    TRUNCATED_PATH,
    "ITEM: TIMESTEP\n0\nITEM: NUMBER OF ATOMS\n3\nITEM: BOX BOUNDS pp pp pp\n" *
    "0.0 30.0\n0.0 30.0\n0.0 30.0\nITEM: ATOMS id type x y z\n1 1 1.0 1.0 1.0\n",
)

# Each case is a frame, its atom count, and the cutoff to use. Ice Ih has
# first neighbours at 2.75 angstrom, so a 0.5 cutoff leaves every one of
# its 128 atoms without a neighbour.
const EMPTY_CASES = (
    (name = "no atoms", frame = read_frame(ZERO_PATH; type = -1), n = 0, cutoff = 3.5),
    (name = "no atoms, guessed oxygen", frame = read_frame(ZERO_PATH), n = 0, cutoff = 3.5),
    (name = "no atom of the kept type", frame = read_frame(Dseams.ice_ih_path(); type = 99), n = 0, cutoff = 3.5),
    (name = "no molecule in the TIP4P/ice frame", frame = read_frame(tip; type = 99), n = 0, cutoff = 3.5),
    (name = "one atom", frame = read_frame(ONE_PATH; type = -1), n = 1, cutoff = 3.5),
    (name = "isolated atoms", frame = read_frame(ISOLATED_PATH; type = -1), n = 3, cutoff = 3.5),
    (name = "ice Ih with a short cutoff", frame = read_frame(Dseams.ice_ih_path(); type = -1), n = 128, cutoff = 0.5),
)

function check_labels(ice::ChillPlus, n)
    @test ice.labels isa Vector{Int32}
    @test length(ice.labels) == n
    @test ice.names isa Vector{String}
    @test length(ice.names) == n
    @test ice.counts isa Dict{String,Int}
    @test length(ice.counts) == NINE_LABELS
    @test sum(values(ice.counts)) == n
    @test all(0 .<= ice.labels .<= NINE_LABELS - 1)
end

function check_cage_score(found::CageScore, n)
    @test found.cage isa Vector{Int32}
    @test length(found.cage) == n
    @test all(0 .<= found.cage .<= 3)
    @test found.n_ih + found.n_ic + found.n_water + found.n_both == n
end

function check_rings(rings::RingHistogram, max_depth)
    @test rings isa RingHistogram
    @test rings.counts isa Dict{Int,Int}
    @test all(3 <= size <= max_depth for size in keys(rings.counts))
    @test all(>(0), values(rings.counts))
end

function check_order(order::SteinhardtOrder, n)
    @test order.ql isa Vector{Float64}
    @test order.qlbar isa Vector{Float64}
    @test length(order.ql) == n
    @test length(order.qlbar) == n
end

@testset "empty frames: $(case.name)" for case in EMPTY_CASES
    frame, n, cutoff = case.frame, case.n, case.cutoff
    @test nop(frame) == n
    @test sprint(show, frame) == "Frame($(n) atoms)"

    @testset "no neighbour inside the cutoff graph" begin
        @test neighbour_pairs(frame; cutoff = cutoff, graph = "cutoff") === 0

        ice = chill_plus(frame; cutoff = cutoff)
        check_labels(ice, n)
        @test ice.counts["water"] == n
        @test all(==(2), ice.labels)
        @test all(==("water"), ice.names)
        @test chill_plus(frame; cutoff = cutoff, graph = "cutoff").labels == ice.labels

        score = cages(frame; cutoff = cutoff, graph = "cutoff")
        check_cage_score(score, n)
        @test score.n_water == n

        rings = primitive_rings(frame; cutoff = cutoff, graph = "cutoff")
        check_rings(rings, 6)
        @test isempty(rings.counts)
        @test all(rings[size] == 0 for size in 0:12)

        for degree in (3, 4, 6, 8, 12)
            order = steinhardt(frame, degree; cutoff = cutoff)
            check_order(order, n)
            @test all(==(0.0), order.ql)
            @test all(==(0.0), order.qlbar)
            @test steinhardt(frame, degree; cutoff = cutoff, graph = "cutoff").ql == order.ql
        end

        local_order = q4_q6(frame; cutoff = cutoff)
        for values in (local_order.q4, local_order.q6, local_order.q4bar, local_order.q6bar)
            @test values isa Vector{Float64}
            @test length(values) == n
            @test all(==(0.0), values)
        end

        for spec in ("512", "5:12,6:2")
            sig = signature_cages(frame, spec; cutoff = cutoff, graph = "cutoff")
            @test sig isa SignatureCages
            @test sig.cages === 0
            @test sig.atoms === 0
        end
    end

    @testset "graphs without a distance bound keep their invariants" begin
        max_pairs = n * (n - 1)
        @test 0 <= neighbour_pairs(frame; cutoff = cutoff, graph = "mutual") <= max_pairs

        check_labels(chill_plus(frame; cutoff = cutoff, graph = "mutual"), n)
        check_cage_score(cages(frame; cutoff = cutoff), n)
        check_cage_score(cages(frame; cutoff = cutoff, graph = "mutual"), n)
        check_rings(primitive_rings(frame; cutoff = cutoff), 6)
        check_rings(primitive_rings(frame; cutoff = cutoff, graph = "mutual", max_depth = 8), 8)
        check_order(steinhardt(frame, 6; cutoff = cutoff, graph = "mutual"), n)
        sig = signature_cages(frame, "512"; cutoff = cutoff, graph = "mutual")
        @test sig.cages >= 0 && sig.atoms >= 0
    end

    @testset "frame-only calls" begin
        labels = symmetry(frame)
        @test labels isa Vector{Int32}
        @test length(labels) == n
        if case.name != "ice Ih with a short cutoff"
            # symmetry takes no cutoff; an atom with no neighbour is -1.
            @test all(==(-1), labels)
        end
        for other in EMPTY_CASES
            tau = jump_tau90(frame, other.frame, 1.0)
            @test tau isa Float64
            @test isnan(tau)
        end
        ice = read_frame(Dseams.ice_ih_path(); type = -1)
        @test isnan(jump_tau90(frame, ice, 2.5))
        @test isnan(jump_tau90(ice, frame, 2.5))
        @test isnan(jump_tau90(frame, frame, 0.0))
        @test isnan(jump_tau90(frame, frame, 1.0; oxygen_type = 7, hydrogen_type = 8))
    end

    @testset "errors are the same on an empty frame" begin
        @test_throws SeamsError neighbour_pairs(frame; cutoff = cutoff, graph = "bogus")
        @test_throws SeamsError neighbour_pairs(frame; cutoff = 0.0)
        @test_throws SeamsError neighbour_pairs(frame; cutoff = -1.0)
        @test_throws SeamsError neighbour_pairs(frame; cutoff = NaN)
        @test_throws SeamsError chill_plus(frame; cutoff = cutoff, graph = "bogus")
        @test_throws SeamsError primitive_rings(frame; cutoff = cutoff, graph = "bogus")
        @test_throws SeamsError primitive_rings(frame; cutoff = cutoff, max_depth = 2)
        @test_throws SeamsError primitive_rings(frame; cutoff = cutoff, max_depth = 0)
        @test_throws SeamsError steinhardt(frame, 5; cutoff = cutoff)
        @test_throws SeamsError steinhardt(frame, 0; cutoff = cutoff)
        @test_throws SeamsError steinhardt(frame, 6; cutoff = cutoff, graph = "bogus")
        @test_throws SeamsError signature_cages(frame, "bogus"; cutoff = cutoff)
        @test_throws SeamsError signature_cages(frame, ""; cutoff = cutoff)
        @test_throws SeamsError signature_cages(frame, "512"; cutoff = cutoff, graph = "bogus")
        @test_throws SeamsError signature_cages(frame, "512"; cutoff = cutoff, graph = "seeded")
        @test_throws SeamsError q4_q6(frame; cutoff = 0.0)
        @test_throws SeamsError q4_q6(frame; cutoff = NaN)
    end
end

@testset "empty frames: path methods and trajectories" begin
    @test nframes(ZERO_PATH) == 1
    ice = chill_plus(ZERO_PATH; type = -1)
    @test ice isa ChillPlus
    @test isempty(ice.labels)
    @test all(==(0), values(ice.counts))
    @test length(ice.counts) == NINE_LABELS

    @test nframes(ZERO_THEN_ONE_PATH) == 2
    @test nop(read_frame(ZERO_THEN_ONE_PATH; frame = 1, type = -1)) == 0
    @test nop(read_frame(ZERO_THEN_ONE_PATH; frame = 2, type = -1)) == 1
    @test chill_plus(ZERO_THEN_ONE_PATH; frame = 1, type = -1).counts["water"] == 0
    @test chill_plus(ZERO_THEN_ONE_PATH; frame = 2, type = -1).counts["water"] == 1
end

@testset "empty frames: read_frame is not silently empty" begin
    # A frame that is out of range is an error, not a frame with no atoms.
    for frame in (0, -1, -100)
        @test_throws SeamsError read_frame(ONE_PATH; frame = frame)
        @test_throws SeamsError read_frame(ZERO_PATH; frame = frame, type = -1)
    end
    for frame in (2, 3, 1000)
        @test_throws SeamsError read_frame(ONE_PATH; frame = frame, type = -1)
        @test_throws SeamsError read_frame(ZERO_PATH; frame = frame, type = -1)
    end
    @test_throws SeamsError read_frame(ZERO_THEN_ONE_PATH; frame = 3, type = -1)
    @test_throws SeamsError read_frame(Dseams.ice_ih_path(); frame = 2, type = -1)
    @test_throws SeamsError read_frame(Dseams.ice_ih_path(); frame = 0, type = -1)
    err = try
        read_frame(ONE_PATH; frame = 7, type = -1)
    catch caught
        caught
    end
    @test err isa SeamsError
    @test occursin("past the last frame", err.message)

    # A file the engine cannot read is an error, not an empty frame.
    @test_throws SeamsError nframes(BLANK_PATH)
    @test_throws SeamsError read_frame(BLANK_PATH; type = -1)
    @test_throws SeamsError read_frame(TRUNCATED_PATH; type = -1)
    @test_throws ErrorException read_frame(joinpath(EMPTY_DIR, "missing.lammpstrj"))
    @test_throws ErrorException nframes(joinpath(EMPTY_DIR, "missing.lammpstrj"))

    # A species filter that keeps nothing is an empty frame, and an error
    # only when the frame is out of range.
    @test nop(read_frame(Dseams.ice_ih_path(); type = 99)) == 0
    @test_throws SeamsError read_frame(Dseams.ice_ih_path(); frame = 2, type = 99)
end

@testset "empty frames: Steinhardt degrees" begin
    ice = read_frame(Dseams.ice_ih_path(); type = -1)
    for degree in (3, 4, 6, 8, 12)
        order = steinhardt(ice, degree)
        @test any(>(0.0), order.ql)
    end
    # The engine has no kernel for other degrees. It used to answer them
    # with a vector of zeros that looks like an empty shell.
    for degree in (-1, 0, 1, 2, 5, 7, 10, 14)
        @test_throws SeamsError steinhardt(ice, degree)
        @test_throws SeamsError steinhardt(ice, degree; graph = "cutoff")
    end
end

@testset "empty frames: ring histogram index" begin
    ice = read_frame(Dseams.ice_ih_path(); type = -1)
    rings = primitive_rings(ice; graph = "cutoff", max_depth = 6)
    @test rings[6] == 256
    @test rings[5] == 0
    @test rings[3] == 0
    @test rings[12] == 0
    @test rings[Int32(6)] == 256
    @test rings.counts == Dict(6 => 256)
end

@testset "empty frames: System without atoms" begin
    sys = System()
    @test seams_system_count(sys) == 0
    @test sprint(show, sys) == "System(0 atoms)"
    calls = (
        "seams_chill" => () -> seams_chill(sys),
        "seams_chill mutual" => () -> seams_chill(sys; graph = 1),
        "seams_steinhardt" => () -> seams_steinhardt(sys, 6),
        "seams_steinhardt average" => () -> seams_steinhardt(sys, 6; average = true),
        "seams_cages" => () -> seams_cages(sys),
        "seams_cages complete" => () -> seams_cages(sys; complete = true),
        "seams_signature_cages" => () -> seams_signature_cages(sys, "512"),
        "seams_neighbours_knn" => () -> seams_neighbours_knn(sys),
        "seams_neighbours_knn union" => () -> seams_neighbours_knn(sys; mutual = false),
        "seams_rdf" => () -> seams_rdf(sys),
        "seams_running_cn" => () -> seams_running_cn(sys),
        "seams_coordination" => () -> seams_coordination(sys),
        "seams_hbonds" => () -> seams_hbonds(sys),
        "seams_density_axis" => () -> seams_density_axis(sys),
        "seams_fingerprint" => () -> seams_fingerprint(sys),
        "seams_contact_pairs" => () -> seams_contact_pairs(sys, "1=cationHead"),
        "seams_domains" => () -> seams_domains(sys, "1=waterO"),
        "seams_prisms" => () -> seams_prisms(sys),
        "seams_monolayer" => () -> seams_monolayer(sys),
        "seams_rings_vertices" => () -> seams_rings_vertices(sys),
        "seams_site_table" => () -> seams_site_table(sys, "1=waterO"),
    )
    for (name, call) in calls
        err = try
            call()
            nothing
        catch caught
            caught
        end
        @test err isa SeamsError
        @test err isa SeamsError && occursin("no frame", err.message)
    end
    @test seams_system_count(sys) == 0

    # A frame with no atoms is refused, and the frame already held stays.
    for (path, type) in ((ZERO_PATH, -1), (ZERO_PATH, 1), (Dseams.ice_ih_path(), 99), (BLANK_PATH, -1))
        @test_throws SeamsError seams_system_read(System(), path, 1, type)
    end
    @test_throws SeamsError seams_system_read(System(), ONE_PATH, 0, -1)
    @test_throws SeamsError seams_system_read(System(), ONE_PATH, 2, -1)
    held = seams_system_read(System(), ISOLATED_PATH, 1, -1)
    @test seams_system_count(held) == 3
    @test_throws SeamsError seams_system_read(held, ZERO_PATH, 1, -1)
    @test_throws SeamsError seams_system_read(held, ISOLATED_PATH, 1, 99)
    @test seams_system_count(held) == 3
    labels, counts = seams_chill(held)
    @test length(labels) == 3
    @test sum(counts) == 3
end

@testset "empty frames: System of atoms with no neighbour" for (name, path, n) in (
    ("one atom", ONE_PATH, 1),
    ("isolated atoms", ISOLATED_PATH, 3),
)
    sys = seams_system_read(System(), path, 1, -1)
    @test seams_system_count(sys) == n

    labels, counts = seams_chill(sys)
    @test labels isa Vector{Int32} && length(labels) == n
    @test counts isa Vector{Int32} && length(counts) == NINE_LABELS
    @test all(==(2), labels)
    @test counts[3] == n && sum(counts) == n
    labels, counts = seams_chill(sys; rule = 1)
    @test length(labels) == n && sum(counts) == n
    labels, counts = seams_chill(sys; graph = 1)
    @test length(labels) == n && sum(counts) == n

    for degree in (3, 4, 6, 8, 12)
        ql, bar = seams_steinhardt(sys, degree)
        @test ql isa Vector{Float64} && length(ql) == n
        @test all(==(0.0), ql)
        @test isempty(bar)
        ql, bar = seams_steinhardt(sys, degree; average = true)
        @test all(==(0.0), ql) && length(bar) == n && all(==(0.0), bar)
    end
    @test_throws SeamsError seams_steinhardt(sys, 5)

    @test seams_cages(sys; graph = 0) == (0, 0, n, 0)
    @test seams_cages(sys; graph = 0, complete = true) == (0, 0, n, 0)
    n_hex, n_cubic, n_water, n_both = seams_cages(sys)
    @test n_hex + n_cubic + n_water + n_both == n
    @test seams_signature_cages(sys, "512") == (0, 0)
    @test_throws SeamsError seams_signature_cages(sys, "bogus")

    @test 0 <= seams_neighbours_knn(sys) <= n * (n - 1)
    @test 0 <= seams_neighbours_knn(sys; mutual = false) <= n * (n - 1)
    @test_throws SeamsError seams_neighbours_knn(sys; k = 0)

    r, g, volume = seams_rdf(sys)
    @test length(r) == length(g) == 8
    @test all(==(0.0), g)
    @test volume > 0
    @test all(==(0.0), seams_running_cn(sys))
    @test length(seams_running_cn(sys)) == 8
    @test seams_coordination(sys) === 0.0
    @test seams_hbonds(sys) === 0
    @test seams_hbonds(sys; oxygen_type = 7, hydrogen_type = 8) === 0

    rho = seams_density_axis(sys)
    @test length(rho) == 4
    @test all(isfinite, rho) && all(>=(0.0), rho)
    key_len, ring_sum = seams_fingerprint(sys)
    @test key_len >= 0
    @test ring_sum === 0
    n_pairs, n_cation, n_anion = seams_contact_pairs(sys, "1=cationHead")
    @test n_pairs === 0
    @test 0 <= n_cation + n_anion <= n
    for subset in (0, 1)
        n_subset, largest, percolation = seams_domains(sys, "1=waterO"; subset = subset)
        @test 0 <= largest <= n_subset <= n
        @test largest <= 1
        @test 0.0 <= percolation <= 1.0
    end
    @test seams_prisms(sys) == zeros(Int32, 7)
    @test seams_monolayer(sys) == zeros(Int32, 7)
    @test seams_monolayer(sys; max_depth = 3) == zeros(Int32, 4)
    for index in (0, 1, 5, -1)
        @test_throws SeamsError seams_rings_vertices(sys; index = index)
    end
    kinds = seams_site_table(sys, "1=waterO")
    @test kinds isa Vector{Int32} && length(kinds) == n
    @test_throws SeamsError seams_site_table(sys, "bogus")
end

@testset "empty frames: System with atoms but no molecule" begin
    # Ice Ih has oxygen only: no hydrogen, so no water molecule is complete.
    sys = seams_system_read(System(), Dseams.ice_ih_path(), 1, -1)
    @test seams_system_count(sys) == 128
    @test seams_hbonds(sys) === 0
    @test seams_hbonds(sys; oxygen_type = 7, hydrogen_type = 8) === 0
    @test seams_hbonds(sys; oxygen_type = 1, hydrogen_type = 9) === 0
    @test seams_contact_pairs(sys, "7=cationHead")[1] === 0
    kinds = seams_site_table(sys, "7=waterO")
    @test length(kinds) == 128
    @test all(==(first(kinds)), kinds)
end
