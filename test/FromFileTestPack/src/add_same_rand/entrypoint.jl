module SameRand
	using FromFile
    @from "../types.jl" import MyInt
    @from "utils.jl" import add_same_rand

    add_same_rand1(x::MyInt)::MyInt = add_same_rand(x)
end