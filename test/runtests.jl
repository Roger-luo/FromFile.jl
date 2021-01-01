using FromFile
using Test

module wrapper1
	using FromFile
	visible = [:A]
	invisible = [:foo, :bar, :baz, :quux, :B, :C]
	
    @from "file.jl" import A
end

module wrapper2
	using FromFile
	visible = [:foo]
	invisible = [:bar, :baz, :quux, :A, :B, :C]
	
	@from "file.jl" import A: foo
end

module wrapper3
	using FromFile
	visible = [:foo, :B]
	invisible = [:bar, :baz, :quux, :A, :C]
	
	@from "file.jl" import A: foo, B
end

module wrapper4
	using FromFile
	visible = [:foo]
	invisible = [:bar, :baz, :quux, :A, :B, :C]
	
    @from "file.jl" import A.foo
end

module wrapper5
	using FromFile
	visible = [:foo, :B]
	invisible = [:bar, :baz, :quux, :A, :B, :C]
	
    @from "file.jl" import A.foo, A.B
end

module wrapper6
	using FromFile
	visible = [:A, :foo, :B]
	invisible = [:bar, :baz, :quux, :C]
	
	@from "file.jl" using A
end

module wrapper7
	using FromFile
	visible = [:foo]
	invisible = [:bar, :baz, :quux, :A, :B, :C]
	
	@from "file.jl" using A: foo
end

module wrapper8
	using FromFile
	visible = [:foo, :B]
	invisible = [:bar, :baz, :quux, :A, :C]
	
	@from "file.jl" using A: foo, B
end

module wrapper9
	using FromFile
	visible = [:A, :C]
	invisible = [:foo, :bar, :baz, :quux, :B]
	
    @from "file.jl" import A, C
end

module wrapper10
	using FromFile
	visible = [:foo, :quux, :A, :B, :C]
	invisible = [:bar, :baz]
	
    @from "file.jl" using A, C
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
		for visible in wrapper.visible
			@eval @test isdefined($wrapper, $(QuoteNode(visible)))
		end
		for invisible in wrapper.invisible
			@eval @test !isdefined($wrapper, $(QuoteNode(invisible)))
		end
	end
	
	# Make sure that the import modules are where we expect them to be
	project_path = dirname(dirname(pathof(FromFile)))
	file_symbol = Symbol(abspath(joinpath(project_path, "test", "file.jl")))
	@test fullname(wrapper1.A) == (:Main, file_symbol, :A)
end