@testset "hsvd" begin
    press = mr_load("twix/sub-SiemensBrainPhantom_seq-svsse_ref-1_avg-1.twix")
    fid = extract_fids(press)
    fid_sup = hsvd_water_suppression(fid)

    @test fid_sup[1] ≈ -6.969325544337758e-6 + 4.1886737243027e-7im
    @test fid_sup[end] ≈ fid[end]
end
