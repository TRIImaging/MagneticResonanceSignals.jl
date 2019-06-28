"""
    FixedString{N}(str)

An ascii string allocated in an immutable fixed length buffer of `N` `UInt8`
code points. This type is intended to be binary compatible with C buffers such
as might be declared with `char buf[16]`.

This is particularly useful for interacting with C libraries or serialized data
structures with fixed length strings.

Currently an ascii encoding is assumed.
"""
struct FixedString{N} <: AbstractString
    data::NTuple{N,UInt8}
end

# constructor / convert 
function FixedString{N}(s::AbstractString) where N
    if !isascii(s)
        throw(ArgumentError("String $(repr(s)) is not ascii"))
    elseif sizeof(s) > N-1
        throw(ArgumentError("String $(repr(s)) does not fit into $N-1 ascii characters"))
    end
    FixedString{N}(ntuple(i->UInt8(i <= sizeof(s) ? s[i] : '\0'), N))
end

Base.convert(::Type{FixedString{N}}, s::FixedString{N}) where {N} = s
Base.convert(::Type{FixedString{N}}, s::AbstractString) where {N} = FixedString{N}(s)

function Base.convert(::Type{String}, s::FixedString)
    vec_data = UInt8[s.data...]
    String(vec_data[1:ncodeunits(s)])
end


# IO
Base.show(io::IO,  s::FixedString) = print(io, typeof(s), "(", repr(convert(String, s)), ")")

Base.write(io::IO, s::FixedString) = write(io, Ref(s))

function Base.read(io::IO, ::Type{<:FixedString{N}}) where N
    read!(io, Ref{FixedString{N}}())[]
end


# AbstractString interface. It's not quite clear what this is yet...
# https://discourse.julialang.org/t/what-is-the-interface-of-abstractstring/8937

# Plenty of assumptions about ascii chars follow!

function Base.ncodeunits(s::FixedString)
    firstnull = findfirst(isequal(0), s.data)
    firstnull != nothing ? firstnull-1 : sizeof(s.data)
end

Base.codeunit(s::FixedString) = UInt8
@inline function Base.codeunit(s::FixedString, i::Integer)
    @boundscheck checkbounds(s, i)
    s.data[i]
end
Base.isvalid(s::FixedString, i::Integer) = true
#Base.@propagate_inbounds Base.nextind(s::FixedString, i::Int) = i+1
Base.length(s::FixedString) = ncodeunits(s)

function Base.iterate(s::FixedString, i::Integer=0)
    i = nextind(s, i)
    (i <= length(s.data) && s.data[i] != 0x00) || return nothing
    return (Char(s.data[i]), i)
end

