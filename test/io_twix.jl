@testset "twix input" begin
    twix = load_twix("twix/sub-SiemensBrainPhantom_seq-svslcosy_inc-1.twix")
    @test length(twix.data) == 1
    acq = twix.data[1]
    @test size(acq.data) == (2080,34)
    @test eltype(acq.data) == ComplexF32
    @test acq.cutoff_pre  == 0x0002
    @test acq.cutoff_post == 0x001e

    @test sprint(show, twix) == """
        MRExperiment metadata:
          Protocol           = svs_lcosy
          Sequence File Name = %CustomerSeq%\\svs_lcosy
          Software Version   = N4_VE11C_LATEST_20160120
          Reference Date     = 2018-11-27T12:22:52
          Coils              = ["HeadNeck_64"]
        Acquisition summary:
          Number   = 1
          Duration = 0.0 s
        """
end

@testset "data extraction" begin
    twix = load_twix("twix/sub-SiemensBrainPhantom_seq-svslcosy_inc-1.twix")
    samples = sampledata(twix, 1, downsample=1)
    @test size(samples) == (2048,34)
    @test first(getaxis(samples, :time)) == 0u"μs"
    @test step(getaxis(samples, :time)) == 500u"μs"
    # This test data used a 64-channel head and neck coil, with a subset of
    # coil elements activated
    @test getaxis(samples, :channel) == [
        :H42,:H43,:H31,:H30,:H63,:H62,:H48,:H49,:H35,:H34,:H40,:H41,:H50,:H70,:H45,
        :H44,:H67,:H66,:H52,:H51,:H46,:H47,:H54,:H53,:H65,:H64,:H71,:H55,:H33,:H32,
        :H61,:H60,:H69,:H68
    ]

    # With downsampling
    samples = sampledata(twix, 1, downsample=2)
    @test size(samples) == (1024,34)
    @test first(getaxis(samples, :time)) == 0u"μs"
    @test step(getaxis(samples, :time)) == 1000u"μs"
end


@testset "coil select parsing" begin
    yaps_dict = TriMRS.parse_header_yaps(String(read("twix/PRESS_TE135_Breast_Coil_Headers/MeasYaps")))
    @test length(@test_logs((:warn, "Could not find some metadata for coil 7"),
                            TriMRS.parse_yaps_rx_coil_selection(yaps_dict))) == 7
end
