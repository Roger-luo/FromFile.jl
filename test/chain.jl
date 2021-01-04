using FromFile
@from "subchain/subfolder/subchain1.jl" import a
@from "subchain/subchain2.jl" import B.b, B.SubB.b2
@from "subchain/subchain3.jl" import C: c
@from "subchain/subchain3.jl" import C2.SubC: c2
@from "subchain/subchain4.jl" using D  # d
@from "subchain/subchain5.jl" using E: e