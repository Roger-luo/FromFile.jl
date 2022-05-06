using FromFile

url = "https://raw.githubusercontent.com/Roger-luo/FromFile.jl/ba3d96b57585a5710579d3d1f18729f06f5087e5/test/basic.jl"

@from "$url" import A

A


function eval_quoted_string(m::Module, s)
    s isa AbstractString && return s
    Meta.isexpr(s, :string) || throw(ArgumentError("expect a string, got $s"))
    tokens = map(s.args) do element
        element isa String && return element
        return Base.eval(m, element)
    end
    return join(tokens)
end

eval_quoted_string(Main, :("$url"))
