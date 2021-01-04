module Square
	using FromFile
    @from "../types.jl" import MyInt
	
    int_square(x::MyInt)::MyInt = MyInt(x.value^2)
end

module Cube
	using FromFile
    @from "../types.jl" import MyInt
	
    int_cube(x::MyInt)::MyInt = MyInt(x.value^3)
end