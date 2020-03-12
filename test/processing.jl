@testset "Spectral downsampling" begin
    # Test Fourier downsampling and signal truncation which is implemented to
    # be compatible with the Siemens way of doing this.
    t = (0:15)/16
    z = exp.(2*π*1im .* t)
    z = reshape(z, length(z), 1) # Add trivial channels dim

    # Know decimated z is numerically equal to Fourier downsampled z, as it's
    # got no frequency content outside the window.
    @test z[1:2:end] ≈ MagneticResonanceSignals.downsample_and_truncate(t, z, 0, 0, 2)[2]  rtol=0 atol=1e-14

    # Currently can't downsample to an odd number of samples
    @test_throws InexactError MagneticResonanceSignals.downsample_and_truncate(t, z, 1, 0, 2)
    @test_throws InexactError MagneticResonanceSignals.downsample_and_truncate(t, z, 0, 1, 2)
    @test_throws InexactError MagneticResonanceSignals.downsample_and_truncate(t, z, 0, 0, 3)

    # Test timing.
    @test t[3:2:end-2] == MagneticResonanceSignals.downsample_and_truncate(t, z, 2, 2, 2)[1]
    @test t[2:end-1] == MagneticResonanceSignals.downsample_and_truncate(t, z, 1, 1, 1)[1]
end

@testset "coil_combination" begin
    # TODO!!
end

@testset "lcosy" begin
    lcosy = @test_logs (:warn,) mr_load("twix/sub-SiemensBrainPhantom_seq-svslcosy_inc-1.twix")

    signal = simple_averaging(lcosy)
    @test size(signal) == (2048,1)
    @test axisnames(signal) == (:time2, :time1)

    # NB: The value of signal[1,1] here is very sensitive to the detail of how
    # channel combination is done.
    #
    # If this test breaks, check channel combination first.
    #
    # Note that we check this in float32 precision, because part of the signal
    # processing is done there. In particular, reduction order in sum()/mean()
    # is implementation defined, so there can be some 1ULP or so difference in
    # simple_averaging() which are system-dependent and cause the tests to be
    # unreliable.
    @test signal[1,1] ≈ 7.738675f-7 - 3.6804267f-6im

    signal = simple_averaging(lcosy, downsample=2)
    @test size(signal) == (1024,1)
    # See comment above regarding channel combination.
    @test signal[1,1] ≈ 5.918123f-6 - 3.929549f-6im
end

@testset "press" begin
    press = mr_load("twix/sub-SiemensBrainPhantom_seq-svsse_ref-1_avg-1.twix")

    signal = simple_averaging(press)
    @test size(signal) == (2048,)
    @test axisnames(signal) == (:time,)

    # NB: The value of signal[1,1] here is very sensitive to the detail of how
    # channel combination is done.
    #
    # If this test breaks, check channel combination first.
    #
    # Note that we check this in float32 precision, because part of the signal
    # processing is done there. In particular, reduction order in sum()/mean()
    # is implementation defined, so there can be some 1ULP or so difference in
    # simple_averaging() which are system-dependent and cause the tests to be
    # unreliable.
    @test signal[1] ≈ 1.285736f-5 - 6.254529f-6im

    signal = simple_averaging(press, downsample=2)
    @test size(signal) == (1024,)
    # See comment above regarding channel combination.
    @test signal[1] ≈ 1.012432f-5 - 5.623437f-6im
end

@testset "Phase correction" begin
    press = mr_load("twix/sub-SiemensBrainPhantom_seq-svsse_ref-1_avg-1.twix")
    spec = spectrum(press)

    # Get estimated zero and first order phase with ernst
    ph0, ph1 = ernst(spec)
    @test ph0 ≈ -2.735754851995358
    @test ph1 ≈ 0.3920045765378072

    # Phase correction
    spec_ph = adjust_phase(spec; zero_phase=ph0, first_phase=ph1)
    @test spec_ph[1] ≈ -2.483368f-6 - 5.092918f-7im
end
