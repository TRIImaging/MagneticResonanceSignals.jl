__precompile__()

module TriMRS

using MicroLogging
using StaticArrays
using DataStructures

include("io_twix.jl")
include("io_felix.jl")
include("io_rda.jl")
include("MRAxis.jl")

include("FIDData.jl")

include("processing.jl")

if isdir(Pkg.dir("PyPlot"))
    using PyPlot
    include("plotting.jl")
end

suspect = nothing
if isdir(Pkg.dir("PyCall"))
    using PyCall
    suspect = try
        pyimport("suspect")
    end
end

const has_suspect = suspect != nothing

if suspect != nothing
    # Functionality from the python suspect library
    include("suspect.jl")
end
suspect = nothing # See __init__

export
    MRExperiment,
    load_twix_raw,
    meta_search,
    timestamp

export SpectroData,
    get_fid,
    fid_length

export
    MRAxis,
    hertz_to_ppm,
    ppm_to_hertz,
    time_axis,
    frequency_axis,
    frequency_axis_ppm

export load_rda,
    save_rda,
    load_twix,
    zero_pad,
    combine_channels

function __init__()
    if has_suspect
        global suspect = try
            pywrap(pyimport("suspect"))
        end
    end
end

end # module
