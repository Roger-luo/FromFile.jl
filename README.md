# FromFile.jl

This is a macro-based implementation of the below spec.

## Problem
Files (as distinct from modules and packages) naturally exhibit a dependency structure. Getting access to one file from another currently relies on using `include`, usually in some "parent" file.

This has two major issues:
- The dependency structure between files is not made explicit;
- topologically sorting the dependency structure (to determine `include` order) is a burden placed upon the developer.

## Solution

The proposal is to extend the `using`/`import` syntax, by giving it a mode by which it can access files.

Each file loaded in this manner would be evaluated in total isolation, stored globally in `PackageName.__toplevel__`, and a binding added to the current context.

If a file has already been loaded then it would be looked up in the global reference rather than being re-evaluated, to avoid duplication issues.

File identity is determined by filesystem location.

As every file then imports its dependencies, then both of the major issues previously identified are resolved.

## Syntax

The suggested syntax is `from "../folder/file.jl" import myobj1, myobj2`, which would expect and require objects with names `:myobj1`, `:myobj2` to be defined inside `file.jl`. These objects could be modules, functions, etc.

If all of `myobj1`, `myobj2`, etc. are modules, then `import` may be replaced with `using` to instead get access to all symbols exported by those modules.

If the specified file does not exist in the specified location, then an error is raised.

Files are looked up relative to the filesystem location of the file in which the statement is written.

Thus, the above is essentially syntactic sugar for:
- Create `PackageName.__toplevel__` if it does not already exist.
- If `PackageName.__toplevel__.Symbol("../folder/file.jl")` does not already exist:
    - Create `PackageName.__toplevel__.Symbol("../folder/file.jl")`.
    - `include("../folder/file.jl")` into `PackageName.__toplevel__.Symbol("../folder/file.jl")`.
- Evaluate one of the following expressions, according to the precise syntax used:
    - `from "../folder/file.jl" import myobj1, myobj2` ---> `import PackageName.__toplevel__.Symbol("../folder/file.jl"): myobj1, myobj2
    - `from "../folder/file.jl" import mymodule: myobj1, myobj2` ---> `import PackageName.__toplevel__.Symbol("../folder/file.jl").mymodule: myobj1, myobj2
    - `from "../folder/file.jl" using mymodule1, mymodule2` ---> `using PackageName.__toplevel__.Symbol("../folder/file.jl").mymodule1, PackageName.__toplevel__.Symbol("../folder/file.jl").mymodule2
    - `from "../folder/file.jl" using mymodule: myobj1, myobj2` ---> `using PackageName.__toplevel__.Symbol("../folder/file.jl").mymodule: myobj1, myobj2

Two other alternate syntaxes for similar behaviour are `from ..folder.file import myobj1, myobj2` and `import "../folder/file.jl": myobj1, myobj2`. These all seem to be essentially equivalent, so there are no strong feelings about which to use. (Those using `from` seem to read a little neater, but do introduce an extra keyword.)

## Alternate proposals

One proposal was to use `import "../folder/file.jl"`, and to expect and require a module with name `:file` to be defined inside `"file.jl"`. However this has additional limitations:
- It does not naturally introduce any symbols into the current scope.
- It does not mesh as well with current Julia, which allows for multiple modules in a file.
- It requires defining a module of the same name as the file, which is a small amount of extra overhead.

One proposal was to to use the syntax `import .file` or `import ..file`. However this has ambiguity issues, as the same syntax can be used to `import` modules in the same file. (Given the right module structure at the point it is invoked.)

One proposal was to try and hook this into the existing package loading mechanism. Doing so via a project environment introduces substantial extra boilerplate. Doing so via an implicit environment lacks the required expressivity, as this looks at the file system for `X/src/X.jl`, and is therefore constrained to expressing trees (which is what file systems are), as opposed to DAGs (which is what general dependency structures are).

One proposal was to use `import "file.jl"` as a shortcut for `include("file.jl"); import .file`. However this does not offer a meaningful improvement in functionality, and in particular does not solve the problems identified at the start.

One proposal was to demand that the filesystem lookup should be done relative to the source root of the package, or pwd in the case of `Main`. However this means that each file implicitly depends upon the entire structure of the rest of the package, which is unnecessary.

One proposal was to ignore the source file's location and use the current module's name to perform lookup wrt the source root of the package; i.e. to look in `src/B/D.jl` when encountering `import "D.jl"` within the module `B`. However this lacks the required expressivity, as it can only express trees, not DAGs.

One proposal was to locate things in `Base.__toplevel__` rather than `PackageName.__toplevel__`. However this doesn't play well with static compilation.
