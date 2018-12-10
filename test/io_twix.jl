
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
    # This test data used a 64-channel head and neck coil, with a subset of
    # coil elements activated
    @test samples.channel == [
        :H42,:H43,:H31,:H30,:H63,:H62,:H48,:H49,:H35,:H34,:H40,:H41,:H50,:H70,:H45,
        :H44,:H67,:H66,:H52,:H51,:H46,:H47,:H54,:H53,:H65,:H64,:H71,:H55,:H33,:H32,
        :H61,:H60,:H69,:H68
    ]

    # With downsampling
    samples = sampledata(twix, 1, downsamp=2)
    @test size(samples) == (1024,34)
    @test first(samples.time) == 0u"μs"
    @test step(samples.time) == 1000u"μs"
end

