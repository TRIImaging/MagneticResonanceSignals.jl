# Misc data processing functionality

"""
    zeropad(fid, pad)

Zero pad an FID for Fourier interpolation
"""
function zeropad(fid, pad)
    pad == 1 ? fid : [fid; zeros(length(fid)*(pad-1))]
end

function zeropad(fid::AxisArray, pad)
    if pad == 1
        return fid
    else
        padded = [fid; zeros(length(fid)*(pad-1))]
        t = AxisArrays.axes(fid, Axis{:time}).val
        t2 = first(t) .+ (0:length(padded)-1)*step(t)
        AxisArray(padded, Axis{:time}(t2))
    end
end

"""
    spectrum(time_samples)

Compute the spectrum from time domain signal via Fourier Transform.

TODO: Extend this to N dimensions of time!
"""
function spectrum(time_samples::AxisArray)
    dim = axisdim(time_samples, Axis{:time})
    spec = fftshift(fft(time_samples.data, dim), dim)
    f = frequency_axis(time_samples)
    AxisArray(spec, Axis{:freq}(f))
end

"""
    sampledata(expt, index; downsample=1)

Return the acquired data from `expt` at a given acqusition `index`.  If
`downsample>1`, the data will be subsampled by the given rate by truncating the
tails of the signal in the Fourier spectral domain. This has the effect of
removing noise by filtering away irrelevant high and low frequency components.
"""
function sampledata(expt, index; downsample=1)
    acq = expt.data[index]
    # The siemens sequence SVS_SE provides a few additional samples before and
    # after the desired ones. They comment that this is mainly to allow some
    # samples to be cut off after downsampling, (presumably to remove some of
    # the ringing artifacts of doing this with a simple FFT).
    cutpre  = acq.cutoff_pre
    cutpost = acq.cutoff_post
    data = acq.data
    # Adjust time so that the t=0 occurs in the first retained sample
    t = ((0:size(data,1)-1) .- cutpre)*dwell_time(expt)
    t,z = downsample_and_truncate(t, data, cutpre, cutpost, downsample)
    coilsyms = if isempty(expt.coils)
        [Symbol("C$i") for i in 1:length(acq.channel_info)]
    else
        # Match channels.
        #
        # This coil data appears to connect to the measurement data via the
        # channel header channel_id field, when the relation
        #
        #     channel_id-1 == adc_channel_connected
        #
        # holds. Why the -1 is here is a mystery - perhaps the channel_id field
        # uses 1-based indexing.
        [Symbol(expt.coils[findfirst(e->e.adc_channel_connected-1 == c.channel_id, expt.coils)].element)
         for c in acq.channel_info]
    end
    channel_ids = [Int(c.channel_id) for c in acq.channel_info]
    AxisArray(z, Axis{:time}(t), Axis{:channel}(coilsyms))
end

# Internal function for downsampling and truncating of acqusition data
function downsample_and_truncate(t, z, cutpre, cutpost, downsample)
    if downsample > 1
        # Do downsampling if requested, via naive Fourier filtering with square
        # window.  This appears to be the way Siemens implement this as well.
        # It's a very spectrum-focussed way to do things and is a bit of an
        # abuse in the time domain.
        #
        # TODO: Do something useful if it's not a whole number of samples,
        # instead of an error?
        s1 = fft(z, 1)
        N = size(s1,1)
        n = Int(N/downsample/2)
        s2 = [s1[1:n,:]; s1[end-n+1:end,:]] ./ downsample
        z = ifft(s2, 1)
        t = t[1:downsample:end]
        cutpre  = Int(cutpre/downsample)
        cutpost = Int(cutpost/downsample)
    end
    # Add descriptive axes to the array and remove 
    t[cutpre+1:end-cutpost], z[cutpre+1:end-cutpost,:]
end

