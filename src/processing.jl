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
        t2 = first(fid.time) .+ (0:length(padded)-1)*step(fid.time)
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
    sampledata(expt, index; downsamp=2)

Return the acquired data from `expt` at a given acqusition `index`.  If
`downsamp>1`, the data will be subsampled by the given rate by truncating the
tails of the signal in the Fourier spectral domain. This has the effect of
removing noise by filtering away irrelevant high and low frequency components.
"""
function sampledata(expt, index; downsamp=2)
    acq = expt.data[index]
    dt = Int(expt.metadata["sRXSPEC.alDwellTime[0]"] / 1000) * u"μs"
    # The siemens sequence SVS_SE provides a few additional samples before and
    # after the desired ones. They comment that this is mainly to allow some
    # samples to be cut off after downsampling, (presumably to remove some of
    # the ringing artifacts of doing this with a simple FFT).
    cutpre  = acq.cutoff_pre
    cutpost = acq.cutoff_post
    _downsample_and_truncate(acq.data, dt, cutpre, cutpost, downsamp)
end

# Internal function for downsampling and truncating an acqusition.
function _downsample_and_truncate(z, dt, cutpre, cutpost, downsamp)
    # Adjust time so that the t=0 occurs in the first retained sample
    t = ((0:size(z,1)-1) .- (cutpre+1))*dt
    if downsamp > 1
        # Do downsampling if requested, via naive FFT with square window.
        # TODO: Do something useful if it's not a whole number of samples,
        # instead of an error?
        s1 = fft(z, 1)
        N = size(s1,1)
        n = Int(N/downsamp/2)
        s2 = [s1[1:n,:]; s1[end-n+1:end,:]]
        z = fft(s2, 1)
        t = t[1:downsamp:end]
        cutpre  = Int(cutpre/downsamp)
        cutpost = Int(cutpost/downsamp)
    end
    # Add descriptive axes to the array and remove 
    fid = AxisArray(z, Axis{:time}(t), Axis{:channel}(1:size(z,2)))
    fid[cutpre+1:end-cutpost,:]
end

