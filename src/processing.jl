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
    spectrum(signal)

Compute the spectrum from time domain signal via Fourier Transform.
"""
function spectrum(signal::AxisArray)
    names = axisnames(signal)
    if names == (:time,)
        spec = fftshift(fft(signal.data))
        f = frequency_axis(signal)
        AxisArray(spec, Axis{:freq}(f))
    elseif names == (:time2, :time1)
        spec = fftshift(fft(signal.data))
        f1 = frequency_axis(signal, Axis{:time1})
        f2 = frequency_axis(signal, Axis{:time2})
        AxisArray(spec, Axis{:freq2}(f2), Axis{:freq1}(f1))
    end
end

# Internal function for downsampling and truncating of acqusition data
function downsample_and_truncate(t, z, cutpre, cutpost, downsample)
    if downsample > 1
        # Do downsampling if requested, via naive Fourier filtering with square
        # window.  This appears to be the way Siemens implement this as well.
        # It's a very spectrum-focused way to do things and is a bit of an
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

