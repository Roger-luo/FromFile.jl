module FromFile

export @from

using Requires

track(mod, path) = nothing

track_modules() = isinteractive()

function __init__()
    @require Revise="295af30f-e4ad-537b-8983-00126c2a3abe" track(mod, path) = Revise.track(mod, path)
end

"""
    @from <path/or/url/to/file>
    @from <path/or/url/to/file> using my_module
    @from <path/or/url/to/file> import my_object
    @from <path/or/url/to/file> import my_module: my_object

Import your object from another Julia script by treating the
script as a module.

# Examples

In `basic.jl` it contains

```julia
module A
    foo() = print("hello")
end
```

and `A` can be imported via

```julia
@from "basic.jl" import A
```

or we can import `foo` that is inside `A`

```julia
@from "basic.jl" using A: foo
@from "basic.jl" import A: foo
```
"""
macro from(path::String, ex::Expr)
    esc(from_m(__module__, __source__, path, ex))
end

macro from(path::String)
    esc(from_m(__module__, __source__, path, Expr(:block))) 
end

function from_m(m::Module, s::LineNumberNode, path::String, root_ex::Expr)
    import_exs = if root_ex.head === :block
        filter(ex -> !(ex isa LineNumberNode), root_ex.args)
    else
        [root_ex]
    end

    all(ex -> ex.head === :using || ex.head === :import, import_exs) || error("expected using/import statement")

    root = Base.moduleroot(m)
    basepath = dirname(String(s.file))

    # file path should always be relative to the
    # module loads it, unless specified as absolute
    # path or the module is created interactively
    if !isabspath(path) && basepath != ""
        path = joinpath(basepath, path)
    end
    path = abspath(path)

    if root === Main
        file_module_sym = Symbol(path)
    else
        file_module_sym = Symbol(relpath(path, pathof(root)))
    end

    if isdefined(root, file_module_sym)
        file_module = getfield(root, file_module_sym)
    else
        file_module = Base.eval(root, :(module $(file_module_sym); include($path); end))

        # In interactive sessions, track generated module using Revise.jl if Revise has been loaded
        track_modules() && track(file_module, path)
    end

    return Expr(:block, map(import_exs) do ex
        loading = Expr(ex.head)

        for each in ex.args
            each isa Expr || continue

            if each.head === :(:) || each.head === :as # using/import A: a, b, c or import A as B
                each.args[1].args[1] === :(.) && error("cannot load relative module from file")
                push!(loading.args, Expr(each.head, Expr(:., fullname(file_module)..., each.args[1].args...), each.args[2:end]...) )
            elseif each.head === :(.) # using/import A, B.C
                each.args[1] === :(.) && error("cannot load relative module from file")
                push!(loading.args, Expr(:., fullname(file_module)..., each.args...))
            else
                error("invalid syntax $ex")
            end
        end
        return loading
    end...)
end

end
