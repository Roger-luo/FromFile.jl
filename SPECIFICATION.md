# Specification

FromFile is an implementation of the following specification, as a draft proposal for an extension to the Julia language. Also see [Issue 4600](https://github.com/JuliaLang/julia/issues/4600) for the ongoing discussion on this topic. (It's worth noting that Stefan [isn't a fan of a new keyword](https://github.com/JuliaLang/julia/issues/39235), so if this ever makes it in the exact syntax may need adjusting!)

## Problem
Files (as distinct from modules and packages) naturally exhibit a dependency structure. Getting access to one file from another currently relies on using `include`, usually in some "parent" file.

This has three major issues:
- The dependency structure between files is not made explicit. Well structured explicit dependencies imply an `O(log n)` dependency structure for a developer understand, in the size of the project `n`. The current system is `O(n)`!
- Each file is executed in an unspecified context. This makes Julia quite fragile. What if an unrelated file accidentally picks the same name for a function? It gets treated as a method and potentially changes the method lookup, as a case of spooky-action-at-a-distance.
- Topologically sorting the dependency structure (to determine `include` order) is a burden placed upon the developer.

It addition, it also often necessitates an unnecessarily verbose `include("file_containing_mymodule.jl"); import MyModule`. _(Which seems to be what initially prompted this issue.)_

## Solution

The proposal is to extend the `using`/`import` syntax, by giving it a mode by which it can access files.

Each file loaded in this manner would be evaluated in total isolation, stored globally in its package (which may be `Main`), and a binding added to the current context.

If a file has already been loaded then it would be looked up in the global reference rather than being re-evaluated, which avoids duplication issues.

File identity is determined by filesystem location.

If the specified file does not exist in the specified location, then an error is raised.

Files are looked up relative to the filesystem location of the file in which the statement is written.

As every file then imports its dependencies, then both of the major issues previously identified are resolved.

## Syntax

The suggested syntax is `from "../folder/file.jl" import myobj1, myobj2`, which would expect and require objects with names `:myobj1`, `:myobj2` to be defined inside `file.jl`. These objects could be modules, functions, etc.

If all of `myobj1`, `myobj2`, etc. are modules, then `import` may be replaced with `using` to instead get access to all symbols exported by those modules. Likewise the other usual variants on this syntax are supported, `... import mymodule: myobj` and so on.

## Implementation

The above is essentially syntactic sugar for:
- If `PackageName.var"folder/file.jl"` does not already exist:
    - Create `PackageName.var"folder/file.jl"` as a module.
    - `include("folder/file.jl")` into `PackageName.var"folder/file.jl"`.
- Evaluate one of the following expressions, according to the precise syntax used, where for readability we let `m` denote `PackageName.var"folder/file.jl"`:
    - `from "folder/file.jl" import myobj1, myobj2`:  
    `import m: myobj1, myobj2`
    - `from "folder/file.jl" import mymodule: myobj1, myobj2`:  
    `import m.mymodule: myobj1, myobj2`
    - `from "folder/file.jl" import mymodule.myobj1, mymodule.myobj2`:  
    `import m.mymodule.myobj1, m.mymodule.myobj2`
    - `from "folder/file.jl" using mymodule1, mymodule2`:  
    `using m.mymodule1, m.mymodule2`
    - `from "folder/file.jl" using mymodule: myobj1, myobj2`:  
    `using m.mymodule: myobj1, myobj2`
    
Wrapping each file into a module is essentially necessary to isolate the contents of each file; however this is an implementation detail not exposed to users.

## Alternate proposals

One proposal was to use `import "../folder/file.jl"`, and to expect and require a module with name `:file` to be defined inside `"file.jl"`. However this has additional limitations:
- It does not naturally introduce any symbols into the current scope.
- It does not mesh as well with current Julia, which allows for multiple modules in a file.
- It requires defining a module of the same name as the file, which is a small amount of extra overhead.

One proposal was to use the syntax `import "../folder/file.jl": myobj1, myobj2`. However this make it seem like `import "../folder/file.jl"` should also be valid, which it is not. (As we don't want to enforce a file<->module equivalence.)

One proposal was to to use the syntax `import .file` or `import ..file`. However this has ambiguity issues, as the same syntax can be used to `import` modules in the same file. (Given the right module structure at the point it is invoked.)

For the above reasons, introducing an additional keyword was seen as the neatest approach.

One proposal was to locate things in `Packagename.__toplevel__` (or some other name like `PackageName.__imports__`), rather than just in `PackageName`. However this doesn't work with precompilation of packages, which produce errors due to the `__toplevel__` module already being closed. _This would mean that we don't pollute the main package namespace, though, so a way to have this work would be desirable._

One proposal was to use the syntax `from ..folder.file import myobj1, myobj2`. However the current syntax better supports getting the file from an arbitrary URI. _For example a proposed extension was to accept URLs, if there is interest in this in the future._

One proposal was to try and hook into the existing package loading mechanism, using that to lookup symbols into paths. However doing so may have ambiguity issues as above, and would introduce substantial extra boilerplate in the form of `Project.toml`/`Manifest.toml` files potentially in every subfolder.

One proposal was to use `import "file.jl"` as a shortcut for `include("file.jl"); import .file`. However this does not offer a meaningful improvement in functionality, and in particular does not solve the two main problems identified at the start.

One proposal was to demand that the filesystem lookup should be done relative to the source root of the package, or pwd in the case of `Main`. (Rather than relative to the file in which the `from` statement is located.) However this means that each file now has nonlocal dependency, on the entire structure of the rest of the package; for example this makes moving whole folders of files much harder.

One proposal was to ignore the source file's location and use the current module's name to perform lookup wrt the source root of the package; i.e. to look in `src/B/D.jl` when encountering `from "D.jl" import ...` within the module `B`. However this lacks the required expressivity, as it can only express trees, not DAGs.
