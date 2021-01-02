using FromFile
@from "subchain1.jl" import a
@from "subchain2.jl" import B.b, B.SubB.b2
@from "subchain3.jl" import C: c
@from "subchain3.jl" import C2.SubC: c2
@from "subchain4.jl" using D  # d
@from "subchain5.jl" using E: e