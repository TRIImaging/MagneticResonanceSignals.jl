__precompile__()

module TriMRS

using MicroLogging
using StaticArrays

include("io_twix.jl")
include("io_felix.jl")

include("FIDData.jl")

include("processing.jl")

# Functionality from python suspect
include("suspect.jl")

export
    MRExperiment,
    load_twix_raw,
    meta_search,
    timestamp

export SpectroData,
    get_fid,
    fid_length,
    hertz_to_ppm,
    ppm_to_hertz,
    time_axis,
    frequency_axis,
    frequency_axis_ppm

export load_twix,
    zero_pad,
    combine_channels

using PyCall

suspect = nothing
function __init__()
    # @pyimport suspect as suspect
    global suspect = pywrap(pyimport("suspect"))
end

end # module
