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

include("io_twix.jl")
include("io_felix.jl")
include("io_rda.jl")
include("MRAxis.jl")

include("FIDData.jl")

include("coil_combination.jl")
include("processing.jl")
include("windows.jl")
include("plotting.jl")

# Data structures and metadata access for MR experiments
export
    MRExperiment,
    meta_search,
    standard_metadata,
    scanner_time

# Old spectro data format. This isn't really useful and should be removed.
export SpectroData,
    get_fid,
    fid_length

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
    load_twix

# Data processing
export
    MRWindows,
    sampledata,
    zeropad,
    pca_channel_combiner,
    combine_channels,
    spectrum

# Plotting
export
    felix_colors

using .MRWindows

@deprecate load_twix_raw load_twix

end # module
