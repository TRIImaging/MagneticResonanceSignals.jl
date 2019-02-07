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

# Plotting
using RecipesBase
using Colors

include("core.jl")
include("LCOSY.jl")

include("io_twix.jl")
include("io_felix.jl")
include("io_rda.jl")

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
    mr_load

# Axes
# TODO: Deprecate / remove all this in favour of AxisArray
export
    MRAxis,
    hertz_to_ppm,
    ppm_to_hertz,
    time_axis,
    frequency_axis,
    frequency_axis_ppm

# IO
export load_rda,
    save_rda,
    load_twix,
    save_felix

# Data processing
export
    MRWindows,
    sampledata,
    zeropad,
    pca_channel_combiner,
    combine_channels,
    spectrum,
    simple_averaging

# Plotting
export
    felix_colors

using .MRWindows

@deprecate load_twix_raw load_twix

end # module
