"""
    MRAxis(f0, dt, numpoints; ppm0=4.7)
    MRAxis(experiment, numpoints; ppm0=4.7)

A combined time and frequency axis object for an MR experiment.

`f0` is the spectrometer frequency in MHz.  `dt` is the time between ADC
samples in seconds (somewhat bizarrely called "dwell time" in Siemens
terminology).

The number of points in FID acquisition is given by `numpoints` - for now we
resist trying to guess this from `expt` until more is known about the
structure there.

`ppm0` is the nominal PPM of the spectrometer reference frequency which is set
to 4.7 by default.  That is, we assume the spectrometer is tuned to the water
resonance, and 4.7 is a chosen nominal chemical shift of water relative to TMS.
Note that this is only approximate because the true shift can vary based on pH,
temperature, etc and you should calibrate your spectral axes against known
metabolites.
"""
struct MRAxis
    f0::Float64    # MHz
    dt::Float64    # s
    n::Int         # 
    ppm0::Float64  # ppm
end

MRAxis(f0, dt, numpoints; ppm0=4.7) = MRAxis(f0, dt, numpoints, ppm0)

function MRAxis(expt::MRExperiment, numpoints; ppm0=4.7)
    # The 1e-6 conversion here is so that we have f0 in MHz. (As a consequence,
    # the factor of 1e6 in unit conversion to ppm happens automatically.)
    # TODO: Argubly ugly, and perhaps should just be in Hz.
    f0 = 1e-6 * expt.metadata["sTXSPEC.asNucleusInfo[0].lFrequency"]
    # The Siemens name "DwellTime" is probably a stretched analogy with radar
    # signal processing terminology.
    dt = 1e-9 * expt.metadata["sRXSPEC.alDwellTime[0]"]
    MRAxis(f0, dt, numpoints, ppm0)
end

# TODO
# Base.show(io::IO, a::MRAxis)

hertz_to_ppm(a::MRAxis, f) = a.ppm0 - f/a.f0
ppm_to_hertz(a::MRAxis, ppm) = (a.ppm0 - ppm)*a.f0

time_axis(a::MRAxis) = a.dt*(0:a.n-1)

function frequency_axis(a::MRAxis)
    # Assume frequency axis is for the data `fftshift(fft(fid))`
    # Offset of zero frequency sample after fftshift is:
    zero_offset = floor(Int, a.n/2)
    (-zero_offset:a.n-1-zero_offset) / (a.n*a.dt)
end

function frequency_axis_ppm(a::MRAxis)
    @warn "Is it right that this flips the axis direction?"
    hertz_to_ppm.(Ref(a), frequency_axis(a))
end

function frequency_axis(a::AxisArray)
    n = length(a.time)
    zero_offset = floor(Int, n/2)
    (-zero_offset:n-1-zero_offset) * uconvert.(u"Hz", one(eltype(a.time))/(n*step(a.time)))
end
