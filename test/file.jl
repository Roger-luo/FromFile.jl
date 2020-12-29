module A

export foo
using Test

function foo()
    @test true
end

end # module A

module B

export should_not_appear
function should_not_appear()
end

end # module B
