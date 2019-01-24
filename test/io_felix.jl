@testset "felix output" begin
    data = ComplexF32[1 4im;
                      2 5im;
                      3 6im]

    io = IOBuffer()
    bandwidth = (123.0, 456.0)
    frequency_Hz = 500.5e6
    save_felix(io, data; bandwidth=bandwidth, frequency=frequency_Hz)

    words = reinterpret(UInt32, take!(io))

    @test words[1] == 0x04030201
    @test words[2] == 256 # Size of header

    header = words[3:3+256-1]
    @test header[121] == 1
    @test header[122] == size(data,1)
    @test header[123] == size(data,2)

    @test all(header[128:133] .== 1)

    fheader = reinterpret(Float32, header)
    @test fheader[134] == frequency_Hz/1e6
    @test fheader[135] == frequency_Hz/1e6

    @test fheader[140] == bandwidth[1]
    @test fheader[141] == bandwidth[2]

    @test words[3+256] == size(data,1)*2
    @test words[3+256 .+ (1:6)] == reinterpret(UInt32, data[:,1])
    @test words[3+256 + 6 + 1] == size(data,1)*2
    @test words[3+256 + 6 + 1 .+ (1:6)] == reinterpret(UInt32, data[:,2])
end
