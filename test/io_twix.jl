@testset "twix input svs_lcosy" begin
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
          Device Id          = ("Siemens", "Prisma", "166042")
          Reference Date     = 2018-11-27T12:22:52
          Frequency          = 123255189 Hz
          Coils              = ["HeadNeck_64"]
        Acquisition summary:
          Number   = 1
          Duration = 0.0 s
        """
end

@testset "twix input press" begin
    # Avg = 1
    twix = load_twix("twix/sub-SiemensBrainPhantom_seq-svsse_ref-1_avg-1.twix")
    @test length(twix.data) == 2
    acq = twix.data[2]
    @test size(acq.data) == (2080,34)
    @test eltype(acq.data) == ComplexF32
    @test acq.cutoff_pre  == 0x0000
    @test acq.cutoff_post == 0x0020

    @test sprint(show, twix) == """
        MRExperiment metadata:
          Protocol           = svs_se-ref-1_avg-1
          Sequence File Name = %SiemensSeq%\\svs_se
          Software Version   = N4_VE11C_LATEST_20160120
          Device Id          = ("Siemens", "Prisma", "166042")
          Reference Date     = 2019-08-22T15:00:28
          Frequency          = 123254849 Hz
          Coils              = ["HeadNeck_64"]
        Acquisition summary:
          Number   = 2
          Duration = 2.0 s
          Loop index 6 in [0,1]   (phase)
        """
    expt = mr_load(twix)
    @test length(expt.press_scans) == 1
    @test length(expt.navigator) == 0
    @test length(expt.ref_scans) == 1

    # Avg = 2
    twix = load_twix("twix/sub-SiemensBrainPhantom_seq-svsse_ref-1_avg-2.twix")
    @test length(twix.data) == 3
    all_acq = twix.data[2:end]
    for acq in all_acq
        @test size(acq.data) == (2080,34)
        @test eltype(acq.data) == ComplexF32
        @test acq.cutoff_pre  == 0x000c
        @test acq.cutoff_post == 0x0014
    end

    @test sprint(show, twix) == """
        MRExperiment metadata:
          Protocol           = svs_se-ref-1_avg-2
          Sequence File Name = %SiemensSeq%\\svs_se
          Software Version   = N4_VE11C_LATEST_20160120
          Device Id          = ("Siemens", "Prisma", "166042")
          Reference Date     = 2019-08-22T15:00:28
          Frequency          = 123254849 Hz
          Coils              = ["HeadNeck_64"]
        Acquisition summary:
          Number   = 3
          Duration = 4.0 s
          Loop index 2 in [0,1]   (acquisition)
          Loop index 6 in [0,1]   (phase)
        """
    expt = mr_load(twix)
    @test length(expt.press_scans) == 2
    @test length(expt.navigator) == 0
    @test length(expt.ref_scans) == 1
end

@testset "twix quality control" begin
    twix = @test_logs (Logging.Warn,r"Unexpected empty meas packet") #=
               =# (Logging.Warn,r"Key lSequenceID has different") #=
               =# (Logging.Warn,r"Key lPtabAbsStartPosZ has different") #=
               =# (Logging.Warn,r"Key bPtabAbsStartPosZValid has different") #=
               =# (Logging.Warn,r"Key sTXSPEC.B1CorrectionParameters.bValid has different") #=
               =# load_twix("twix/sub-SiemensBrainPhantom_seq-svslcosy_incomplete.twix")
    @test MagneticResonanceSignals.AcquisitionsIncomplete in twix.quality_control

    valid_twix_bytes = read("twix/sub-SiemensBrainPhantom_seq-svslcosy_inc-1.twix")

    partially_zeroed_twix = copy(valid_twix_bytes)
    partially_zeroed_twix[0x69:end] .= 0
    twix = @test_logs (Logging.Warn,r"Unexpected empty measurement header sections") match_mode=:any #=
        =# load_twix(IOBuffer(partially_zeroed_twix))
    @test MagneticResonanceSignals.MeasHeaderEmpty in twix.quality_control

    truncated_twix = copy(valid_twix_bytes)
    truncated_twix = truncated_twix[1:900_000]
    twix = @test_logs (Logging.Warn,r"Twix acquisition truncated at position 900000") #=
        =# (Logging.Warn,r"Key lSequenceID has different") #=
        =# (Logging.Warn,r"Key lPtabAbsStartPosZ has different") #=
        =# (Logging.Warn,r"Key bPtabAbsStartPosZValid has different") #=
        =# (Logging.Warn,r"Key sTXSPEC.B1CorrectionParameters.bValid has different") #=
        =# load_twix(IOBuffer(truncated_twix))
    @test MagneticResonanceSignals.AcquisitionsIncomplete in twix.quality_control
end

@testset "metadata parsing" begin
    twix = load_twix("twix/sub-SiemensBrainPhantom_seq-svslcosy_inc-1.twix")
    @test twix.metadata["tProtocolName"] == "svs_lcosy"
    @test twix.metadata["sTXSPEC.asNucleusInfo[0].lFrequency"] == 123255189
    @test twix.metadata["sTXSPEC.asNucleusInfo[0].lFrequency"] == 123255189

    @test twix.metadata["Dicom.ManufacturersModelName"] == "Prisma"
    @test twix.metadata["Dicom.DeviceSerialNumber"] == "166042"

    @test twix.metadata["Meas.tReferenceImage0"] == "1.3.12.2.1107.5.2.43.166042.2018112712225215359633498"
    @test twix.metadata["Meas.tReferenceImage1"] == "1.3.12.2.1107.5.2.43.166042.2018112712230494362433518"
    @test twix.metadata["Meas.tReferenceImage2"] == "1.3.12.2.1107.5.2.43.166042.2018112712231775153533538"
    @test twix.metadata["Meas.tFrameOfReference"] == "1.3.12.2.1107.5.2.43.166042.1.20181127122016414.0.0.4988"
end


@testset "data extraction" begin
    twix = load_twix("twix/sub-SiemensBrainPhantom_seq-svslcosy_inc-1.twix")
    samples = sampledata(twix, 1) # downsample==1
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
    # Test values of first and last time samples of channel data
    @test samples[1,1]     == -1.3986137f-6 + 1.442153f-6im
    @test samples[1,end]   ==  2.022367f-6  - 5.987473f-6im
    @test samples[end,1]   == -1.3408717f-6 - 3.1664968f-7im
    @test samples[end,end] == -3.306195f-8  - 7.7229924f-7im

    # With downsampling
    samples = sampledata(twix, 1, downsample=2)
    @test size(samples) == (1024,34)
    @test first(getaxis(samples, :time)) == 0u"μs"
    @test step(getaxis(samples, :time)) == 1000u"μs"
end


@testset "coil select parsing" begin
    yaps_dict = MagneticResonanceSignals.parse_header_yaps(String(read("twix/PRESS_TE135_Breast_Coil_Headers/MeasYaps")))
    @test length(@test_logs((:warn, "Could not find some metadata for coil 7"),
                            MagneticResonanceSignals.parse_yaps_rx_coil_selection(yaps_dict))) == 7
end


