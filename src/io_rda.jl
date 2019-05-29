"""
    load_rda(rda_file)

Load header dictionary and spectroscopy data from a Siemens .rda file.  Returns
`header,data`, where `header` is a simple dictionary containing the ASCII
header, and `data` is the time domain induced magnetization signal.

Single voxel spectroscopy data will be loaded as a vector containing the single
magnentization signal.

For spectroscopy with a spatial component (that is, CSI data with at least one
header field `CSIMatrixSize[i]` not equal to 1), an array of size N×I×K×J will
be returned where I,J,K are the CSI indices 0,1,2 and the FID length is N.
"""
function load_rda(io::IO)
    firstline = readline(io)
    if firstline != ">>> Begin of header <<<"
        error("Expected RDA header, got: $firstline")
    end
    # Read header
    header = OrderedDict{String,String}()
    while true
        if eof(io)
            throw(EOFError("RDA file ended while reading header"))
        end
        # TODO: Is the encoding correct here?
        line = readline(io)
        if line == ">>> End of header <<<"
            break
        end
        # To split array indices...
        # r"^(\w+)(?:\[(\d+)\])?:\s*(.*)$",
        m = match(r"^(\S+)\s*:\s*(.*)$", line)
        if m == nothing
            @error "BUG: could not match RDA header line \"$line\""
        end
        header[m[1]] = m[2]
    end
    vecsize = parse(Int, header["VectorSize"])
    csi_dims = [parse(Int, get(header, "CSIMatrixSize[$i]", "1")) for i=0:2]
    # RDA should always be channel combined (& averaged?), so expect a single
    # FID per voxel.
    data_dims = prod(csi_dims) == 1 ? (vecsize,) : (vecsize, csi_dims...)
    raw_data = read(io)
    if sizeof(raw_data) != prod(data_dims)*sizeof(ComplexF64)
        error("""
              Wrong amount of raw data in .rda file.
              Expected $data_dims ComplexF64's. Got $(length(raw_data)) bytes instead.""")
    end
    data = Array{ComplexF64}(undef, data_dims)
    copy!(data, reshape(reinterpret(ComplexF64, raw_data), data_dims))
    header, data
end

load_rda(fname::AbstractString) = open(load_rda, fname)


"""
    save_rda(file, header, data)

Save a single FID as Siemens format .rda.  `header` should be a dictionary of
key values for the rda ASCII header.
"""
function save_rda(io::IO, header::AbstractDict, data)
    if parse(Int, header["VectorSize"]) != size(data,1)
        error("rda header VectorSize mismatches with length(data)")
    end
    for dim in 2:4
        csi_key = "CSIMatrixSize[$(dim-2)]"
        h_size = parse(Int, get(header, csi_key, "1"))
        d_size = size(data, dim)
        if h_size != d_size
            error("rda header entry $csi_key=$h_size is inconsistent with data dimension $dim of length $d_size")
        end
    end
    write(io, ">>> Begin of header <<<\r\n")
    for (key,val) in header
        write(io, "$key: $val\r\n")
    end
    write(io, ">>> End of header <<<\r\n")
    write(io, ComplexF64.(data))
    nothing
end

save_rda(fname::String, header, data) = open(io->save_rda(io, header, data), fname, "w")
