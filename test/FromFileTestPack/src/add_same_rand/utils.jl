using FromFile

@from "../types.jl" import MyInt

myrand = floor(Int, 1000 * rand())

add_same_rand(x::MyInt)::MyInt = MyInt(x.value + myrand)