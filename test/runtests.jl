using TriMRS
using TriMRS.MRWindows
using AxisArrays
using Test

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
    @test size(sampledata(twix, 1, downsamp=1)) == (2048,34)
    @test size(sampledata(twix, 1, downsamp=2)) == (1024,34)
end

@testset "processing" begin
    twix = load_twix("sub-SiemensBrainPhantom_seq-svslcosy_inc-1.twix")
    @test size(sampledata(twix, 1, downsamp=1)) == (2048,34)
    @test size(sampledata(twix, 1, downsamp=2)) == (1024,34)
end

@testset "windowing" begin
    A = AxisArray([1.0 2.0;
                   3.0 4.0], Axis{:time}(1:2), Axis{:channel}(1:2))
    # Triangular window; should be evaluated to give
    # [1, 0.5] along time dimension of length 2.
    testwindow(t) = 1-t
    @test MRWindows.apply_window!(A, testwindow) == [1    2;
                                                     1.5  2]

    A = AxisArray([1.0, 1.0, 1.0], Axis{:time}(1:3))
    @test sinebell(A, skew=1.5, n=2) == [0, 0.32311591129511724, 0.9807289153754679]
end

end
