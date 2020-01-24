using MagneticResonanceSignals: FixedString

@testset "FixedString" begin
    # Constructor
    @test FixedString{5}("abcd").data == (0x61, 0x62, 0x63, 0x64, 0x00)
    @test_throws ArgumentError("String \"α\" is not ascii") FixedString{5}("α")
    @test_throws ArgumentError("String \"abcd\" does not fit into 4-1 ascii characters") FixedString{4}("abcd")
    @test convert(FixedString{4}, FixedString{4}("abc")) === FixedString{4}("abc")
    @test convert(FixedString{4}, "abc") === FixedString{4}("abc")
    @test convert(String, FixedString{4}("abc"))::String == "abc"

    # show
    @test sprint(show, FixedString{10}("abcd")) == "FixedString{10}(\"abcd\")"
    @test sprint(show, FixedString{10}("ab\"cd")) == "FixedString{10}(\"ab\\\"cd\")"

    # IO
    writebuf = IOBuffer()
    @test write(writebuf, FixedString{6}("abcd")) == 6
    @test take!(writebuf) == UInt8['a', 'b', 'c', 'd', '\0', '\0']

    readbuf = IOBuffer(UInt8['a', 'b', 'c', 'd', '\0', '\0'])
    @test read(readbuf, FixedString{6}) == FixedString{6}("abcd")
    @test position(readbuf) == 6

    # AbstractString interface
    @test length(FixedString{10}("abc")) == 3
    @test codeunit(FixedString{10}("abc")) == UInt8
    @test ncodeunits(FixedString{10}("abc")) == 3
    @test ncodeunits(FixedString{2}((UInt8('a'),UInt8('b')))) == 2

    # Iteration
    @test collect(FixedString{10}("abc")) == ['a', 'b', 'c']
    @test collect(FixedString{10}("abc")) == ['a', 'b', 'c']
end
