module FromFile

export @from, @from_url

using Requires: @require
using Downloads: download

track(mod, path) = nothing

track_modules() = isinteractive()

function __init__()
    @require Revise="295af30f-e4ad-537b-8983-00126c2a3abe" track(mod, path) = Revise.track(mod, path)
end

macro from(path, ex::Expr)
    esc(from_m(__module__, __source__, path, ex))
end

macro from(path)
    esc(from_m(__module__, __source__, path))
end

macro from_url(path, ex::Expr)
    esc(from_url_m(__module__, __source__, path, ex))
end

macro from_url(path)
    esc(from_url_m(__module__, __source__, path))
end

# NOTE: we'd like to keep this pacakge minimal deps
# so just copy paste this one-liner
# Source: IsUrl.jl (MIT license)
function isurl(str::AbstractString)
    windowsregex = r"^[a-zA-Z]:[\\]"
    urlregex = r"^[a-zA-Z][a-zA-Z\d+\-.]*:"
    return !occursin(windowsregex, str) && occursin(urlregex, str)
end

function from_m(m::Module, s::LineNumberNode, path, root_ex::Expr = Expr(:block))
    path = eval_quoted_string_expr(m, path)
    return from_local_file(m, s, path, root_ex)
end

function from_url_m(m::Module, s::LineNumberNode, url, root_ex::Expr = Expr(:block))
    url = eval_quoted_string_expr(m, url)
    isurl(url) || throw(ArgumentError("expects an URL"))
    return from_remote_file(m, s, url, root_ex)
end

function eval_quoted_string_expr(m::Module, str)
    str isa String && return str
    Meta.isexpr(str, :string) || throw(ArgumentError("expect a String, got $str"))
    tokens = map(str.args) do s
        s isa String && return s
        return Base.eval(m, s)
    end
    return join(tokens)
end

function from_remote_file(m::Module, s::LineNumberNode, url::String, root_ex::Expr)
    root = Base.moduleroot(m)
    file_module_sym = Symbol(url)
    file_module = lazy_load_file(root, file_module_sym) do
        download(url) 
    end
    return load_symbols_from_file(file_module, file_module_sym, parse_import_stmts(root_ex))
end

function from_local_file(m::Module, s::LineNumberNode, path::String, root_ex::Expr)
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

    file_module = lazy_load_file(path, root, file_module_sym)
    return load_symbols_from_file(file_module, file_module_sym, parse_import_stmts(root_ex))
end

function parse_import_stmts(root_ex::Expr)
    import_exs = if root_ex.head === :block
        filter(ex -> !(ex isa LineNumberNode), root_ex.args)
    else
        [root_ex]
    end

    all(ex -> ex.head === :using || ex.head === :import, import_exs) || error("expected using/import statement")
    return import_exs
end

function lazy_load_file(path::String, root::Module, file_module_sym::Symbol)
    return lazy_load_file(()->path, root, file_module_sym)
end

function lazy_load_file(f, root::Module, file_module_sym::Symbol)
    if isdefined(root, file_module_sym)
        file_module = getfield(root, file_module_sym)
    else
        path = f()
        file_module = Base.eval(root, :(module $(file_module_sym); include($path); end))
        # In interactive sessions, track generated module using Revise.jl if Revise has been loaded
        track_modules() && track(file_module, path)
    end
    return file_module
end

function load_symbols_from_file(file_module::Module, file_module_sym::Symbol, @nospecialize(import_exs))
    ret = Expr(:block)
    for ex in import_exs
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
        push!(ret.args, loading)
    end
    return ret
end

end
