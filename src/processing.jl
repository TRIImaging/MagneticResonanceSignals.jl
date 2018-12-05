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

# TODO: Should only match on an AxisArray with :time ???
function FFTW.fft(fid::AxisArray, args...; kwargs...)
    dim = axisdim(fid, Axis{:time})
    fftd = fft(fid.data, dim)
    f = frequency_axis(fid)
    AxisArray(fftd, Axis{:freq}(f))
end

# TODO: Should only match on an AxisArray with :freq???
function FFTW.fftshift(spec::AxisArray, args...; kwargs...)
    dim = axisdim(spec, Axis{:freq})
    shifted = fftshift(spec.data, dim)
    AxisArray(shifted, AxisArrays.axes(spec))
end

"""
    combine_avg(expt, r; downsamp=1)
"""
function combine_avg(expt, r; downsamp=1)
    acqs = expt.data[r]
    combiner = pca_channel_combiner(acqs) # Crude!
    z = mean(combiner.(acqs))
    dt = Int(expt.metadata["sRXSPEC.alDwellTime[0]"] / 1000) * u"μs"
    t = (0:length(z)-1)*dt
    if downsamp > 1
        # Do downsampling if requested, via naive FFT with square window.
        # TODO 2: Do something useful if it's not a whole number of samples,
        # instead of an error?
        s1 = fft(z)
        n = Int(length(s1)/downsamp/2)
        s2 = [s1[1:n]; s1[end-n+1:end]]
        z = fft(s2)
        t = t[1:downsamp:end]
    end
    # Remove excess samples
    fid = AxisArray(z, Axis{:time}(t))
    cutpre  = Int(expt.data[r][1].cutoff_pre/downsamp)
    cutpost = Int(expt.data[r][1].cutoff_post/downsamp)
    fid[cutpre+1:end-cutpost]
end
