"""
    MRAxis(f0, dt, numpoints; ppm0=4.7)
    MRAxis(experiment, numpoints; ppm0=4.7)

A combined time and frequency axis object for an MR experiment.

The number of points in FID acquisition is given by `numpoints` - for now we
resist trying to guess this from `expt` until more is known about the potential
structure.

`ppm0` is the nominal PPM of the spectrometer reference frequency which is set
to 4.7 by default.  That is, we assume the spectrometer is tuned to the water
peak, 4.7 being our chosen nominal chemical shift of water relative to TMS.
(The true shift can vary based on pH, temperature, etc.)
"""
struct MRAxis
    f0::Float64
    dt::Float64
    n::Int
    ppm0::Float64
end

MRAxis(f0, dt, numpoints; ppm0=4.7) = MRAxis(f0, dt, numpoints, ppm0)

function MRAxis(expt::MRExperiment, numpoints; ppm0=4.7)
    # TODO: Is this is stored in μHz?
    f0 = 1e-6 * expt.metadata["sTXSPEC.asNucleusInfo[0].lFrequency"]
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

frequency_axis_ppm(a::MRAxis) = hertz_to_ppm.(a, frequency_axis(a))
