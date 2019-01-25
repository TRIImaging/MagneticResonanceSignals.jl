@testset "felix output" begin
    data = ComplexF32[1 4im;
                      2 5im;
                      3 6im]

    io = IOBuffer()
    bandwidth = (123u"Hz", 456u"Hz")
    frequency = 500.5u"MHz"
    save_felix(io, data; bandwidth=bandwidth, frequency=frequency)

    words = reinterpret(UInt32, take!(io))

    # Just some basic tests here, to check that the metadata gets in the
    # correct place and the data is appended.
    @test words[1] == 0x04030201
    @test words[2] == 256 # Size of header

    header = words[3:3+256-1]
    @test header[121] == 1
    @test header[122] == size(data,1)
    @test header[123] == size(data,2)

    @test all(header[128:133] .== 1)

    fheader = reinterpret(Float32, header)
    @test fheader[134] == frequency/u"MHz"
    @test fheader[135] == frequency/u"MHz"

    @test fheader[140] == bandwidth[1]/u"Hz"
    @test fheader[141] == bandwidth[2]/u"Hz"

    @test words[3+256] == size(data,1)*2
    @test words[3+256 .+ (1:6)] == reinterpret(UInt32, data[:,1])
    @test words[3+256 + 6 + 1] == size(data,1)*2
    @test words[3+256 + 6 + 1 .+ (1:6)] == reinterpret(UInt32, data[:,2])
end
