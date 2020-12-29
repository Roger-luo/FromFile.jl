module FromFile

export @from

const loaded_path = Dict{String, Module}()

macro from(path::String, ex)
    esc(from_m(__module__, path, ex))
end

function from_m(m::Module, path::String, ex::Expr)
    ex.head === :using || ex.head === :import || error("expect using/import statement")
    path = abspath(normpath(path))
    loading = Expr(ex.head)
    root = root_module(m)
    file_module = load_module(root, path)

    for each in ex.args
        each isa Expr || continue

        if each.head === :(:) # using/import A: a, b, c
            m_name = each.args[1].args[1]
            m_name === :(.) && error("cannot load relative module from file")
            if root === Main
                push!(loading.args, Expr(:(:), Expr(:., :., fullname(file_module)..., m_name), each.args[2:end]...) )
            else
                push!(loading.args, Expr(:(:), Expr(:., fullname(file_module)..., m_name), each.args[2:end]...) )
            end
        elseif each.head === :(.) # using/import A, B, C
            m_name = each.args[1] # module name
            m_name === :(.) && error("cannot load relative module from file")

            if root === Main
                push!(loading.args, Expr(:., :., fullname(file_module)..., m_name))
            else
                push!(loading.args, Expr(:., fullname(file_module)..., m_name))
            end
        else
            error("invalid syntax $ex")
        end
    end

    if root === Main && (isinteractive() || !isdefined(Main, Symbol(path)))
        return quote
            $(Symbol(path)) = $file_module
            $loading
        end
    end
    return loading
end

function load_module(root::Module, path::String)
    if root === Main
        return load_module_from_main(path)
    else
        return load_module_from_package(root, path)
    end
end

function load_module_from_main(path)
    file_module_sym = Symbol(path)
    # always reload file when it's in interactive mode and in Main
    if haskey(loaded_path, path) && !isinteractive()
        return loaded_path[path]
    else
        file_module = Base.eval(Base.__toplevel__, :(module $(file_module_sym) end))
        Base.include(file_module, path)
        loaded_path[path] = file_module
        return file_module
    end
end

function load_module_from_package(root, path)
    toplevel_symbol = Symbol("#__toplevel__#")
    file_module_sym = Symbol(relpath(path, pathof(root)))
    if isdefined(root, toplevel_symbol) # package
        toplevel = getfield(root, toplevel_symbol)
    else
        toplevel = Base.eval(root, :(baremodule $toplevel_symbol; using Base; end))
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
