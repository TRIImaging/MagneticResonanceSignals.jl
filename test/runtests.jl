using TriMRS
using TriMRS.MRWindows
using AxisArrays
using Test
using Unitful

@testset "TriMRS" begin

@testset "twix input" begin
    twix = load_twix("sub-SiemensBrainPhantom_seq-svslcosy_inc-1.twix")
    @test length(twix.data) == 1
    acq = twix.data[1]
    @test size(acq.data) == (2080,34)
    @test eltype(acq.data) == ComplexF32
    @test acq.cutoff_pre  == 0x0002
    @test acq.cutoff_post == 0x001e
end

@testset "data extraction" begin
    twix = load_twix("sub-SiemensBrainPhantom_seq-svslcosy_inc-1.twix")
    samples = sampledata(twix, 1, downsamp=1)
    @test size(samples) == (2048,34)
    @test first(samples.time) == 0u"μs"
    @test step(samples.time) == 500u"μs"

    # With downsampling
    samples = sampledata(twix, 1, downsamp=2)
    @test size(samples) == (1024,34)
    @test first(samples.time) == 0u"μs"
    @test step(samples.time) == 1000u"μs"
end

include("processing.jl")
include("windows.jl")

end
