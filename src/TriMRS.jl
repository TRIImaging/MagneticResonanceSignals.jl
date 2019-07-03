module TriMRS

using StaticArrays
using DataStructures
using AxisArrays

using Statistics
using Unitful
using FFTW

using LinearAlgebra

# Plotting
using RecipesBase
using Colors

include("core.jl")
include("LCOSY.jl")

include("fixedstring.jl")  # IO Util

include("io_twix.jl")
include("io_felix.jl")
include("io_rda.jl")
include("io_nmrpipe.jl")

# TODO: Kill off MRAxis
include("MRAxis.jl")

include("coil_combination.jl")
include("processing.jl")

include("windows.jl")
include("plotting.jl")

# Data structures and metadata access for MR experiments
export
    MRExperiment,
    meta_search,
    standard_metadata,
    scanner_time,
    mr_load,
    sampledata

# IO
export load_rda,
    save_rda,
    load_twix,
    save_felix,
    save_nmrpipe

# Conversion utils
export twix_to_nmrpipe

# Axes
# TODO: Deprecate / remove all this in favour of AxisArray
export
    MRAxis,
    hertz_to_ppm,
    ppm_to_hertz,
    time_axis,
    frequency_axis,
    frequency_axis_ppm

# Low level signal processing
export
    # Channel combination
    pca_channel_combiner,
    combine_channels,
    # Spectral windows
    zeropad,
    apply_window, apply_window!,
    sinebell

# High level signal processing
export
    # Averaging of repeats
    simple_averaging,
    # Fourier transform
    spectrum

# Plotting
export
    felix_colors

@deprecate load_twix_raw load_twix

const _local_basefactors = Unitful.basefactors

function __init__()
    Unitful.register(TriMRS)
    merge!(Unitful.basefactors, _local_basefactors)
end

end # module
