# Copyright (c) d-SEAMS developers
# Tests for optional readcon-core (.con) and chemfiles (PDB, GRO) readers.
# Each format testset is gated solely on the corresponding feature query so
# builds without optional readers skip cleanly while builds with them must pass.

const FIXTURE_DIR = joinpath(@__DIR__, "fixtures")
const CON_FIXTURE = joinpath(FIXTURE_DIR, "tiny_multi_cuh2.con")
const PDB_FIXTURE = joinpath(FIXTURE_DIR, "water.pdb")
const GRO_FIXTURE = joinpath(FIXTURE_DIR, "water.gro")

@testset "engine reader features" begin
    feats = features()
    @test feats isa NamedTuple{(:chemfiles, :readcon),Tuple{Bool,Bool}}
    @test has_chemfiles() isa Bool
    @test has_readcon() isa Bool
    @test feats.chemfiles === has_chemfiles()
    @test feats.readcon === has_readcon()
end

@testset "read .con (readcon-core)" begin
    if has_readcon()
        f1 = read_frame(CON_FIXTURE; frame = 1, type = -1)
        f2 = read_frame(CON_FIXTURE; frame = 2, type = -1)
        @test nop(f1) == 4
        @test nop(f2) == 4
        @test length(chill_plus(f1).labels) == 4
        @test neighbour_pairs(f1) >= 0

        sys = seams_system_read(System(), CON_FIXTURE, 1, -1)
        @test seams_system_count(sys) == 4
    else
        @test_throws SeamsError read_frame(CON_FIXTURE; type = -1)
        @test nop(read_frame(CON_FIXTURE; type = -1)) == 4 skip = true
    end
end

@testset "read PDB (chemfiles)" begin
    if has_chemfiles()
        @test nframes(PDB_FIXTURE) == 1
        all_atoms = read_frame(PDB_FIXTURE; frame = 1, type = -1)
        @test nop(all_atoms) == 12
        oxygens = read_frame(PDB_FIXTURE; frame = 1, type = 0)
        @test nop(oxygens) == 4
        @test length(chill_plus(oxygens).labels) == 4
        @test neighbour_pairs(oxygens) >= 0

        sys = seams_system_read(System(), PDB_FIXTURE, 1, -1)
        @test seams_system_count(sys) == 12
    else
        @test_throws SeamsError read_frame(PDB_FIXTURE; type = -1)
        @test nop(read_frame(PDB_FIXTURE; type = -1)) == 12 skip = true
    end
end

@testset "read GRO (chemfiles)" begin
    if has_chemfiles()
        @test nframes(GRO_FIXTURE) == 1
        all_atoms = read_frame(GRO_FIXTURE; frame = 1, type = -1)
        @test nop(all_atoms) == 12
        oxygens = read_frame(GRO_FIXTURE; frame = 1, type = 0)
        @test nop(oxygens) == 4
        @test length(chill_plus(oxygens).labels) == 4
        @test neighbour_pairs(oxygens) >= 0

        sys = seams_system_read(System(), GRO_FIXTURE, 1, -1)
        @test seams_system_count(sys) == 12
    else
        @test_throws SeamsError read_frame(GRO_FIXTURE; type = -1)
        @test nop(read_frame(GRO_FIXTURE; type = -1)) == 12 skip = true
    end
end
