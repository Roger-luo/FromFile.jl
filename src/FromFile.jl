module FromFile

export @from

macro from(path::String, ex::Expr)
    esc(from_m(__module__, __source__, path, ex))
end

function from_m(m::Module, s::LineNumberNode, path::String, ex::Expr)
    ex.head === :using || ex.head === :import || error("expect using/import statement")
	
	root = Base.moduleroot(m)
	basepath = dirname(String(s.file))
	
    # file path should always be relative to the
    # module loads it, unless specified as absolute
    # path or the module is created interactively
    if !isabspath(path) && basepath != ""
        path = joinpath(basepath, path)
    else
        path = abspath(path)
    end
	
    loading = Expr(ex.head)
    
    if root === Main
        file_module_sym = Symbol("##", path)
    else
        file_module_sym = Symbol("##", relpath(path, pathof(root)))
    end

    if isdefined(root, file_module_sym)
        file_module = getfield(root, file_module_sym)
    else
        file_module = Base.eval(root, :(module $(file_module_sym); include($path); end))
    end

    for each in ex.args
        each isa Expr || continue

        if each.head === :(:) # using/import A: a, b, c
            each.args[1].args[1] === :(.) && error("cannot load relative module from file")
            push!(loading.args, Expr(:(:), Expr(:., fullname(file_module)..., each.args[1].args...), each.args[2:end]...) )
        elseif each.head === :(.) # using/import A, B.C
            each.args[1] === :(.) && error("cannot load relative module from file")
            push!(loading.args, Expr(:., fullname(file_module)..., each.args...))
        else
            error("invalid syntax $ex")
        end
    end
    return loading
end

end
