"""
    FixedString{N}(str)

A zero terminated string allocated in a fixed length buffer of `N` bytes.

This is useful for interacting with C libraries which represent strings in
fixed size buffers of `char`.
"""
struct FixedString{N}  # TODO? <: AbstractString
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

Base.convert(::Type{FixedString{N}}, s::AbstractString) where {N} = FixedString{N}(s)

function Base.convert(::Type{String}, s::FixedString)
    vec_data = UInt8[s.data...]
    firstnull = findfirst(isequal(0), vec_data)
    String(vec_data[1:(firstnull != nothing ? firstnull-1 : end)])
end

# IO
Base.show(io::IO,  s::FixedString) = print(io, typeof(s), "(", repr(convert(String, s)), ")")

Base.write(io::IO, s::FixedString) = write(io, Ref(s.data))

function Base.read(io::IO, ::Type{FixedString{N}}) where N
    rdata = Ref{NTuple{N,UInt8}}()
    read!(io, rdata)
    FixedString{N}(rdata[])
end

