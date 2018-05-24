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

export
    MRExperiment,
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
    load_twix

export
    zero_pad,
    pca_channel_combiner,
    combine_channels

@deprecate load_twix_raw load_twix

end # module
