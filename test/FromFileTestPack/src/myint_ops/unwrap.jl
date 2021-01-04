using FromFile
@from "../types.jl" import MyInt
@from "ops.jl" import Square

int_unwrap(x::MyInt)::Int = x.value
int_square_unwrap(x::MyInt)::Int = int_unwrap(Square.int_square(x))