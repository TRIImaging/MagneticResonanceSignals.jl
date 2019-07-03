using Unitful, TriMRS, Test
using TriMRS: FixedString
using AxisArrays

@testset "NMRPipe format IO" begin
    test_header = [
       # Name              Type               Offset            Ground truth
        ("FDFLTFORMAT",    Float32,           1,                4.0086362f9),
        ("FDFLTORDER",     Float32,           2,                Float32(2.3450000286102295)),
        ("FDDIMCOUNT",     Float32,           9,                2),
        ("FDF3SIZE",       Float32,           15,               1.),
        ("FDF2LABEL",      FixedString{8},    16,               "X"),
        ("FDF1LABEL",      FixedString{8},    18,               "Y"),
        ("FDF3LABEL",      FixedString{8},    20,               "Z"),
        ("FDF4LABEL",      FixedString{8},    22,               "A"),
        ("FDDIMORDER1",    Float32,           24,               2.0),
        ("FDDIMORDER2",    Float32,           25,               1.0),
        ("FDDIMORDER3",    Float32,           26,               3.0),
        ("FDDIMORDER4",    Float32,           27,               4.0),
        ("FDF4SIZE",       Float32,           32,               1.),
        ("FDF1QUADFLAG",   Float32,           55,               0.0),
        ("FDF2QUADFLAG",   Float32,           56,               0.0),
        ("FDF2CAR",        Float32,           66,               Float32(1.2)),
        ("FDF1CAR",        Float32,           67,               0),
        ("FDF2CENTER",     Float32,           79,               2.0),
        ("FDF1CENTER",     Float32,           80,               5.0),
        ("FDF3CENTER",     Float32,           81,               1.),
        ("FDF4CENTER",     Float32,           82,               1.),
        ("FDF2APOD",       Float32,           95,               2.0),
        ("FDREALSIZE",     Float32,           97,               8.0),
        ("FDSIZE",         Float32,           99,               8.0),
        ("FDF2SW",         Float32,           100,              1000.0),
        ("FDF2ORIG",       Float32,           101,              Float32(147.7476)),
        ("FDF2OBS",        Float32,           119,              Float32(123.123)),
        ("FDF1OBS",        Float32,           218,              Float32(123.123)),
        ("FDSPECNUM",      Float32,           219,              4.0),
        ("FDF2FTFLAG",     Float32,           220,              0.0),
        ("FDF1FTFLAG",     Float32,           222,              0.0),
        ("FDF1SW",         Float32,           229,              Float32(1250)),
        ("FDF1ORIG",       Float32,           249,              Float32(468.75 * -1)),
        ("FD2DPHASE",      Float32,           256,              0.0),
        ("FDF2TDSIZE",     Float32,           386,              2.0),
        ("FDF1TDSIZE",     Float32,           387,              8.0),
        ("FD2DVIRGIN",     Float32,           399,              1.),
        ("FDF1APOD",       Float32,           428,              8.0),
        ("FDFILECOUNT",    Float32,           442,              1.),
        ("FDF1AQSIGN",     Float32,           475,              16),
    ]
    test_data = rand(8,4)
    test_data_ax = AxisArray(test_data,
                             Axis{:time2}((0.0:1.0:7.0)*u"ms"),
                             Axis{:time1}((0.0:0.8:2.4)*u"ms"))
    # Test write NMR Pipe into buffer
    buf = IOBuffer()
    save_nmrpipe(buf, test_data_ax, (Axis{:time1}, Axis{:time2});
                 frequency=123.123u"MHz", ref_freq_offset=(0.0u"ppm", 1.2u"ppm"))
    # Test read the NMR Pipe from buffer and ensure all values are correct
    # 1. Assert header (512 * 4-byte array)
    for (key,type,offset,ground_truth) in test_header
        seek(buf, offset*4)
        @test read(buf, type) == ground_truth
    end

    # 2. Assert data with test_data
    seek(buf, 512*4)
    # Written data: r r r ... i i i ... r r r ... i i i ... and so on
    #               where r = real and i = imaginary
    for i = size(test_data_ax, Axis{:time1}()):-1:1
        fid = test_data_ax[Axis{:time1}(i), Axis{:time2}(:)]
        for real_time2 in real.(fid)
            value = reinterpret(Float32, read(buf, 4))
            @test value[1] == Float32(real_time2)
        end

        for imag_time2 in imag.(fid)
            value = reinterpret(Float32, read(buf, 4))
            @test value[1] == Float32(imag_time2)
        end
    end
end
