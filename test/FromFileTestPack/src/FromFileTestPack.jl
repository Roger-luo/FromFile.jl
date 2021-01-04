module FromFileTestPack

export MyInt, add_same_rand1, add_same_rand2, int_square, int_cube, int_unwrap, int_square_unwrap

using FromFile
@from "types.jl" import MyInt
@from "add_same_rand/entrypoint.jl" import SameRand: add_same_rand1
@from "add_same_rand/another_entrypoint.jl" import add_same_rand2
@from "myint_ops/ops.jl" import Square.int_square, Cube.int_cube
@from "myint_ops/unwrap.jl" import int_unwrap, int_square_unwrap
end