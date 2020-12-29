using FromFile
using Test

@from "test/file.jl" using A

const project_path = dirname(dirname(pathof(FromFile)))

@testset "Main using A" begin
    @test fullname(A) == (Symbol(abspath(joinpath(project_path, "test", "file.jl"))), :A)
    foo()
end
