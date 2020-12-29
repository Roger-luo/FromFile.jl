module FromFile

export @from

# This replicates Base.__toplevel__
baremodule __toplevel__
    using Base
end

macro from(path::String, ex)
    esc(from_m(__module__, path, ex))
end

function from_m(m::Module, path::String, ex::Expr)
    ex.head === :using || ex.head === :import || error("expect using/import statement")
    path = abspath(normpath(path))
    loading = Expr(ex.head)
    root = root_module(m)

    if root === Main
        toplevel = __toplevel__
    else
        toplevel_symbol = :__toplevel__
        if isdefined(root, toplevel_symbol) # package
            toplevel = getfield(root, toplevel_symbol)
        else
            toplevel = Base.eval(root, :(baremodule $toplevel_symbol; using Base; end))
        end
    end
    
    file_module = load_module(toplevel, root, path)

    for each in ex.args
        each isa Expr || continue

        if each.head === :(:) # using/import A: a, b, c
            m_name = each.args[1].args[1]
            m_name === :(.) && error("cannot load relative module from file")
            push!(loading.args, Expr(:(:), Expr(:., fullname(file_module)..., m_name), each.args[2:end]...) )
        elseif each.head === :(.) # using/import A, B, C
            m_name = each.args[1] # module name
            m_name === :(.) && error("cannot load relative module from file")
            push!(loading.args, Expr(:., fullname(file_module)..., m_name))
        else
            error("invalid syntax $ex")
        end
    end
    return loading
end

function load_module(toplevel::Module, root::Module, path::String)
    if root === Main
        file_module_sym = Symbol(path)
    else
        file_module_sym = Symbol(relpath(path, pathof(root)))
    end

    if isdefined(toplevel, file_module_sym)
        file_module = getfield(toplevel, file_module_sym)
    else
        file_module = Base.eval(toplevel, :(module $(file_module_sym); end))
        Base.include(file_module, path)
    end

    return file_module
end

function root_module(m::Module)
    root = parentmodule(m)
    prev = m
    while root !== prev
        prev = root
        root = parentmodule(root)
    end
    return root
end

end
