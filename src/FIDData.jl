"""
    struct FIDData{T,N}

A container for an `Array{T,N}` of MR FID data.

TODO: This data structure assume the experiment densely samples the parameter
space (eg, the t1 increments for COSY), but that's not always the case.  Need
to figure out how to represent more flexible experiments.
"""
struct FIDData{T,N}
    data::Array{T,N}
    f0::Float64
    dt::Float64
    te::Float64
    ppm0::Float64
    metadata
end

FIDData(data, f0, dt, te; ppm0=4.7, metadata=Dict()) = FIDData(data, f0, dt, te, ppm0, metadata)

function Base.show(io::IO, fids::FIDData)
    data = fids.data
    print(io, """
          FIDData with data of shape $(size(data)):
              fid acquisition:
                 fid length   = $(size(data,4))
                 dt           = $(fids.dt) s
                 f0           = $(fids.f0) Hz
                 te           = $(fids.te) s
                 num_channels = $(size(data,3))
                 num_repeats  = $(size(data,1))
                 n_t1         = $(size(data,2))
              auxiliary:
                 ppm0             = $(fids.ppm0)
                 length(metadata) = $(length(fids.metadata))
          """
    )
end

"""
    get_fid(fids, t1_index, repetition, channel)

Get the time domain FID for a given `repetition`, `t1_index` and `channel`.
"""
function get_fid(fids::FIDData, t1_index, repetition, channel)
    fids.data[repetition,t1_index,channel,:]
end

"""
    fid_length(fids)

Return the number of samples in each FID stored in `fids`.
"""
fid_length(fids::FIDData) = size(fids.data)[end]

"""
    hertz_to_ppm(fids, f)

Converts a frequency in Hz to a relative frequency in PPM.
"""
hertz_to_ppm(fids::FIDData, f) = fids.ppm0 - f/fids.f0

"""
    ppm_to_hertz(fids, ppm)

Converts a relative frequency in PPM to a frequency in Hz.
"""
ppm_to_hertz(fids::FIDData, ppm) = (fids.ppm0 - ppm)*fids.f0

"""
    time_axis(fids)

Get the time for the FID samples, starting from 0 s
"""
time_axis(fids::FIDData) = fids.dt*(0:fid_length(fids)-1)

"""
    frequency_axis(fids; pad=1)

Get the frequency axis for the FID samples, in Hz, when fourier transformed and shifted.

Set `pad` to a positive integer to get the frequency axis for a padded FID of
length `pad*fid_length(fids)`.
"""
function frequency_axis(fids::FIDData; pad=1)
    N = pad*fid_length(fids)
    df = 1/fids.dt
    df*((0:N-1)/N - 0.5)
end

"""
    frequency_axis_ppm(fids; pad=1)

Get the frequency axis for FID samples, in ppm
"""
frequency_axis_ppm(fids::FIDData; pad=1) = hertz_to_ppm.(fids, frequency_axis(fids,pad=pad))


