
"""
Read a spectrum file in Felix ".mat" format

(Felix is software for 2D spectroscopy.)
"""
function read_felix_spectrum(fname)
    @warn "read_felix_spectrum is mostly untested!" max_log=1
    header,rawdata = open(fname) do io
        read(io, 2^14), read(io, 2^22)
    end

    # Felix spectral data appears to be stored in big endian Float32 in the last
    # section of the file.
    #
    # Furthermore, the data layout is not a simple strided matrix, but looks like a
    # set of 128x32 image tiles.
    #
    # It also looks like this data might be magnitude only (??)
    tilesize = (128,32)
    ntiles = (16,16)
    spectrum_size = tilesize .* ntiles
    data_tiles = reshape(ntoh.(reinterpret(Float32, rawdata)), tilesize..., ntiles...)

    # Reshape data from tiled format into a normal strided format
    reshape(permutedims(data_tiles, (1,3,2,4)), spectrum_size...)
end

