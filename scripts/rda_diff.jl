# To install dependencies:
#
# Pkg.add("DataStructures")

using DataStructures

# Copied from TriMRS
"""
    load_rda(rda_file)

Load header dictionary and FID data from a Siemens .rda file.
This has only basic support for loading a single FID.

Returns `header,data`, where `header` is a simple dictionary containing the
ASCII header, and `data` is the FID.
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
            warn("BUG: could not match RDA header line \"$line\"")
        end
        header[m[1]] = m[2]
    end
    csi_length = prod(get(header, "CSIMatrixSize[$i]", "1") != 1 for i=1:3)
    csi_length == 1 || error("CSI data shape not implemented")
    # RDA should always be channel combined (& averaged?)
    raw_data = read(io)
    data = reinterpret(Complex128, raw_data)
    if length(data) != parse(Int,header["VectorSize"])
        error("Unexpected .rda data length $(length(data))")
    end
    header, data
end

load_rda(fname::AbstractString) = open(load_rda, fname)


"""
    save_rda(file, header, data)

Save a single FID as Siemens format .rda.  `header` should be a dictionary of
key values for the rda ASCII header.
"""
function save_rda(io::IO, header::Associative, data)
    if parse(Int, header["VectorSize"]) != length(data)
        error("rda header VectorSize mismatches with length(data)")
    end
    write(io, ">>> Begin of header <<<\r\n")
    for (key,val) in header
        write(io, "$key: $val\r\n")
    end
    write(io, ">>> End of header <<<\r\n")
    write(io, Complex128.(data))
    nothing
end

save_rda(fname::String, header, data) = open(io->save_rda(io, header, data), fname, "w")


# Simple diffing function
function rda_diff(in1file, in2file, outfile; anonymize=true)
    in1header,in1data = load_rda(in1file)
    in2header,in2data = load_rda(in2file)
    outheader = copy(in1header)
    if anonymize
        outheader["PatientName"] = "xxxxxxxxx"
        outheader["PatientID"] = "xxx"
        outheader["PatientBirthDate"] = "20000101"
    end
    save_rda(outfile, outheader, in1data .- in2data)
end

# To run from command line:
#=
if length(ARGS) != 3
    println("Usage: julia rda_diff.jl input1.rda  input2.rda  output_1_minus_2.rda")
    exit(1)
end

rda_diff(ARGS...)
=#
