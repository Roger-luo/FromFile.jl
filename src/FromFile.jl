module FromFile

export @from

using MatchCore

# This replicates Base.__toplevel__
baremodule __toplevel__
    using Base
end

const loaded_path = String[]

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
    else # package
        toplevel = Base.eval(root, :(baremodule $(gensym(__toplevel__));using Base;end))
    end

    for each in ex.args
        each isa Expr || continue

        if each.head === :(:) # using/import A: a, b, c
            each.args[1].args[1] === :(.) && error("cannot load relative module from file")
            m_name = each.args[1].args[1]
            file_module = load_module(toplevel, root, path, m_name)
            push!(loading.args, Expr(:(:), Expr(:., fullname(file_module)..., m_name), each.args[2:end]...) )
        elseif each.head === :(.) # using A, B, C
            each.args[1] === :(.) && error("cannot load relative module from file")
            m_name = each.args[1] # module name
            file_module = load_module(toplevel, root, path, m_name)
            # create binding
            push!(loading.args, Expr(:., fullname(file_module)..., m_name))
        else
            error("invalid syntax $ex")
        end
    end
    return loading
end

function load_module(toplevel::Module, root::Module, path::String, name::Symbol)
    # evaluate file
    # 1. create a path module inside __toplevel__
    if root === Main
        file_module_sym = Symbol(path)
    else
        file_module_sym = Symbol(relpath(path, pathof(root)))
    end

    if isdefined(toplevel, file_module_sym)
        file_module = getfield(toplevel, file_module_sym)
    else
        file_module = Base.eval(toplevel, :(baremodule $(file_module_sym);using Base;end))
    end
    # 2. evaluate the file inside the path module, so we get identical module path
    if !(path in loaded_path)
        Base.include(file_module, path)
        push!(loaded_path, path)
    end

    if !isdefined(file_module, name)
        error("cannot find module $name from $path")
    end
    return file_module
end

function root_module(m::Module)
    root = parentmodule(m)
    while root !== m
        root = parentmodule(m)
    end
    return root
end

end
