@testset "core" begin
    @test uconvert(u"ppm", 1.0u"Hz"/1.0u"MHz") == 1.0u"ppm"
end
