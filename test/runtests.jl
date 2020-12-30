using FromFile
using Test

module wrapper1
	using FromFile
    @from "test/file.jl" import A
end

module wrapper2
	using FromFile
	@from "test/file.jl" import A: foo
end

module wrapper3
	using FromFile
	@from "test/file.jl" import A: foo, B
end

module wrapper4
	using FromFile
    @from "test/file.jl" import A.foo
end

module wrapper5
	using FromFile
    @from "test/file.jl" import A.foo, A.B
end

module wrapper6
	using FromFile
	@from "test/file.jl" using A
end

module wrapper7
	using FromFile
	@from "test/file.jl" using A: foo
end

module wrapper8
	using FromFile
	@from "test/file.jl" using A: foo, B
end

module wrapper9
	using FromFile
    @from "test/file.jl" import A, C
end

module wrapper10
	using FromFile
    @from "test/file.jl" using A, C
end

@testset "Tests from REPL" begin
	# Make sure that we're not affecting this namespace
	@test !isdefined(@__MODULE__, :A)
	@test !isdefined(@__MODULE__, :foo)
	@test !isdefined(@__MODULE__, :bar)
	@test !isdefined(@__MODULE__, :B)
	@test !isdefined(@__MODULE__, :baz)
	@test !isdefined(@__MODULE__, :C)
	@test !isdefined(@__MODULE__, :quux)
	
	for wrapper in (wrapper1, wrapper2, wrapper3, wrapper4, wrapper5, wrapper6, wrapper7, wrapper8, wrapper9, wrapper10)
		@eval begin
			# Make sure that the module A does or doesn't make it in
			if $wrapper in (wrapper1, wrapper6, wrapper9, wrapper10)
				@test isdefined($wrapper, :A)
				@test isdefined($wrapper.A, :foo)
				@test isdefined($wrapper.A, :bar)
				@test $wrapper.A.foo() == "hello"
				@test $wrapper.A.bar() == "goodbye"
				@test isdefined($wrapper.A, :B)
				@test isdefined($wrapper.A.B, :baz)
				@test $wrapper.A.B.baz == 5
			else
				@test !isdefined($wrapper, :A)
			end
			
			# Make sure that the various attributes all either do or don't make it in.
			if $wrapper in (wrapper3, wrapper6, wrapper8, wrapper10)
				@test isdefined($wrapper, :foo)
				@test isdefined($wrapper, :B)
			elseif $wrapper in (wrapper2, wrapper7)
				@test isdefined($wrapper, :foo)
				@test !isdefined($wrapper, :B)
			elseif $wrapper === wrapper4
				@test isdefined($wrapper.A, :foo)
				@test !isdefined($wrapper.A, :B)
			elseif $wrapper === wrapper5
				@test isdefined($wrapper.A, :foo)
				@test isdefined($wrapper.A, :B)
			else
				@test !isdefined($wrapper, :foo)
				@test !isdefined($wrapper, :B)
			end
			@test !isdefined($wrapper, :bar)
			
			
			# Make sure that the module C either does or doesn't make it in
			if $wrapper === wrapper9
				@test isdefined($wrapper, :C)
				@test !isdefined($wrapper, :quux)
			elseif $wrapper === wrapper10
				@test isdefined($wrapper, :C)
				@test isdefined($wrapper, :quux)
			else
				@test !isdefined($wrapper, :C)
				@test !isdefined($wrapper, :quux)
			end
		end
	end
	
	# Make sure that the import modules are where we expect them to be
	project_path = dirname(dirname(pathof(FromFile)))
	file_symbol = Symbol(abspath(joinpath(project_path, "test", "file.jl")))
	@test fullname(wrapper1.A) == (:FromFile, :__toplevel__, file_symbol, :A)
	@test isdefined(FromFile.__toplevel__, file_symbol)
end