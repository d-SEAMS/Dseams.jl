# Copyright (c) d-SEAMS developers
# Run each script in examples/ in its own process, in the test project, and
# check its exit status and the census line it prints. A failed @assert in a
# script is a non-zero exit.

const EXAMPLES = joinpath(pkgdir(Dseams), "examples")

function run_example(name, args...)
    script = joinpath(EXAMPLES, name)
    cmd = `$(Base.julia_cmd()) --startup-file=no --project=$(Base.active_project()) $script $args`
    out = IOBuffer()
    err = IOBuffer()
    proc = run(pipeline(ignorestatus(cmd); stdout = out, stderr = err))
    text = String(take!(out))
    success(proc) || @error "$(name) failed" text String(take!(err))
    return success(proc), text
end

@testset "examples" begin
    ok, text = run_example("lang_tasks.jl")
    @test ok
    @test strip(text) == "pairs 512 rings 0 0 0 0 0 0 256 chill 0 128 0 0 0 0 0 0 0"

    ok, text = run_example("julia_api.jl")
    @test ok
    @test strip(text) == "julia api ok"
end

if !isempty(root)
    @testset "examples on seams-core data" begin
        ok, text = run_example("core_counts.jl")
        @test ok
        @test strip(text) == "julia hexagonal 128 rings6 256 clathrate 136 rings5 144"

        ok, text = run_example("minimal_julia.jl", joinpath(root, "input", "traj", "genice_sI.lammpstrj"))
        @test ok
        @test strip(text) == "julia example ok"

        ok, text = run_example("science_tutorials.jl", root)
        @test ok
        for line in (
            "interface hexagonal 352 water 434 interfacial 49 cubic 1",
            "interface layers HHHHHHHHC",
            "nucleus cubic 47 hexagonal 62 water 3589 interfacial 240",
            "nucleus axis x layers CHHHCHHHHHHHHH",
            "cages sII 512 16",
            "cages sII 51264 8",
            "cages sH 512 12",
            "cages sH sh 8",
            "cages sH 51268 4",
        )
            @test occursin(line, text)
        end
    end
end
