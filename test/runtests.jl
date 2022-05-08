import Pkg
Pkg.develop(path = joinpath(@__DIR__, "FromFileTestPack"))

include("test_repl.jl")
include("test_remote.jl")
