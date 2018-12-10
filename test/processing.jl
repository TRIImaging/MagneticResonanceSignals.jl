@testset "Spectral downsampling" begin
    # Test Fourier downsampling and signal truncation which is implemented to
    # be compatible with the Siemens way of doing this.
    t = (0:15)/16
    z = exp.(2*π*1im .* t)
    z = reshape(z, length(z), 1) # Add trivial channels dim

    # Know decimated z is numerically equal to Fourier downsampled z, as it's
    # got no frequency content outside the window.
    @test z[1:2:end] ≈ TriMRS.downsample_and_truncate(z, step(t), 0, 0, 2)  rtol=0 atol=1e-14

    # Currently can't downsample to an odd number of samples
    @test_throws InexactError TriMRS.downsample_and_truncate(z, step(t), 1, 0, 2)
    @test_throws InexactError TriMRS.downsample_and_truncate(z, step(t), 0, 1, 2)
    @test_throws InexactError TriMRS.downsample_and_truncate(z, step(t), 0, 0, 3)

    # Test timing.
    @test t[1:2:end-4] == TriMRS.downsample_and_truncate(z, step(t), 2, 2, 2).time
    @test t[1:end-2] == TriMRS.downsample_and_truncate(z, step(t), 1, 1, 1).time
end

#=
@testset "processing" begin
end
=#
