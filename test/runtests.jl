using MagneticResonanceSignals
using AxisArrays
using Test
using Unitful

# UUGH. See the improvements at https://github.com/JuliaArrays/AxisArrays.jl/pull/152
getaxis(samples, name) = AxisArrays.axes(samples, Axis{name}).val

@testset "MagneticResonanceSignals" begin

include("core.jl")
include("mr_load.jl")
include("processing.jl")
include("windows.jl")

include("fixedstring.jl")
include("io_twix.jl")
include("io_rda.jl")
include("io_felix.jl")
include("io_nmrpipe.jl")

end
