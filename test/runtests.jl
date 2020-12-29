using FromFile
using Test

@from "test/file.jl" using A

path = abspath("test/file.jl")
m = getfield(From.__toplevel__, Symbol(path))
