module parent

using FromFile
@from "revise/subfile.jl" import child

g1() = child.f1()^2
g2() = child.f2()^2
g3() = child.f3()^2

end
