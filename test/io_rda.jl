@testset "RDA IO, single voxel" begin
    header,data = load_rda("rda/single_voxel_example.rda")

    # Basic header reading
    @test header["PatientName"] == "Foo"
    @test header["PatientBirthDate"] == "19700101"
    @test header["TR"] == "2000.000000"
    @test header["PixelSpacing3D"] == "20.000000"
    @test length(header) == 83

    fake_fid = ComplexF64.(1:1024, 1024:-1:1)
    @test size(data) == size(fake_fid)
    @test data == fake_fid

    # Test exact roundtrip through save_rda
    io = IOBuffer()
    save_rda(io, header, data)
    @test read("rda/single_voxel_example.rda") == take!(io)
end

@testset "RDA IO, CSI" begin
    header,data = load_rda("rda/CSI_example.rda")

    # Check that data came through correctly shaped
    fake_csi_data = reshape(ComplexF64.(1:64*2*3*1, 64*2*3*1:-1:1), 64,2,3,1)
    @test size(data) == size(fake_csi_data)
    @test data == fake_csi_data

    # Test exact roundtrip through save_rda
    io = IOBuffer()
    save_rda(io, header, data)
    @test read("rda/CSI_example.rda") == take!(io)
end
