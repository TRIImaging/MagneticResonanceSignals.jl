__precompile__()

module TriMRS

using MicroLogging
using StaticArrays
using DataStructures
using AxisArrays

using Statistics
using Unitful
using FFTW

using Compat
using Compat.LinearAlgebra

using RecipesBase

include("io_twix.jl")
include("io_felix.jl")
include("io_rda.jl")
include("MRAxis.jl")

include("FIDData.jl")

include("coil_combination.jl")
include("processing.jl")
include("windows.jl")
include("plotting.jl")

export
    MRExperiment,
    meta_search,
    standard_metadata,
    scanner_time

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
    MRWindows,
    sampledata,
    zeropad,
    pca_channel_combiner,
    combine_channels,
    spectrum

using .MRWindows

@deprecate load_twix_raw load_twix

end # module
