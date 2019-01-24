using TriMRS
using TriMRS.MRWindows
using AxisArrays
using Test
using Unitful

# UUGH. See the improvements at https://github.com/JuliaArrays/AxisArrays.jl/pull/152
getaxis(samples, name) = AxisArrays.axes(samples, Axis{name}).val

@testset "TriMRS" begin

include("io_twix.jl")
include("io_felix.jl")
include("processing.jl")
include("windows.jl")

end
