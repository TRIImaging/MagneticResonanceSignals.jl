using Logging

@testset "mr_load integration test" begin
    # TODO: This is far too trivial! should get / generate some better test data.
    cosy = @test_logs (:warn,r"Key lSequenceID has different") #=
        =# (:warn,r"Key lPtabAbsStartPosZ has different") #=
        =# (:warn,r"Key bPtabAbsStartPosZValid has different") #=
        =# (:warn,r"Key sTXSPEC.B1CorrectionParameters.bValid has different") #=
        =# (:warn,r"Sequence.*is not one of the versions I recognize"s) #=
        =# mr_load("twix/sub-SiemensBrainPhantom_seq-svslcosy_inc-1.twix")

    @test size(cosy.lcosy_scans) == (1,1)
    @test size(cosy.ref_scans) == (0,)
    @test step(cosy.t1) == 0.8u"ms"
end

