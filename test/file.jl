module A

export foo
using Test

function foo()
    @test true
end

end