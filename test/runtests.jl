using TriMRS
using TriMRS.MRWindows
using AxisArrays
using Test
using Unitful

@testset "TriMRS" begin

include("io_twix.jl")
include("processing.jl")
include("windows.jl")

end
