# Misc data processing functionality

"""
    zeropad(fid, axis, pad)

Zero pad an FID for Fourier interpolation
"""
function zeropad(signal::AxisArray, axis=Axis{:time}, pad=2)
    if pad == 1
        return signal
    else
        dim = axisdim(signal, axis)
        padsize = [size(signal)...]
        padsize[dim] *= (pad-1)
        padded = cat(signal, zeros(padsize...), dims=dim)
        t = AxisArrays.axes(signal, axis).val
        tnew = first(t) .+ (0:size(padded,dim)-1)*step(t)
        newaxes = [AxisArrays.axes(signal)...]
        newaxes[dim] = axis(tnew)
        AxisArray(padded, newaxes...)
    end
end

"""
    simple_averaging(fids)

Do simple averaging from FIDs
"""
function simple_averaging(fids::AxisArray)
    d = axisdim(fids, Axis{:phase_cycle})
    averaged_signal = dropdims(mean(fids, dims=d), dims=d)
end

"""
    spectrum(signal::AxisArray)

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

"""
    function adjust_phase(spectrum, zero_phase=0.0, first_phase=0.0, fixed_frequency=0.0)

Adjust phases of the signal.

# Example

```
expt = mr_load("path/to/twix")
spec = spectrum(expt)
ph0, ph1 = ernst(spec)
spec_ph = adjust_phase(spec; zero_phase=ph0, first_phase=ph1)
```
"""
function adjust_phase(
    spectrum::AbstractArray; dt=0.0008, zero_phase=0.0, first_phase=0.0, fixed_frequency=0.0
)
    sw = 1.0/dt
    np = size(spectrum)[end]
    phase_ramp = Vector(range(-sw/2, stop=sw/2, length=np+1)[1:end-1])

    phase_shift = zero_phase .+ first_phase * (fixed_frequency .+ phase_ramp)
    spectrum .* exp.(1im .* phase_shift)
end

function adjust_phase(
    spectrum::AxisArray; dt=0.0008, zero_phase=0.0, first_phase=0.0, fixed_frequency=0.0
)

    AxisArray(
        adjust_phase(
            spectrum.data;
            dt=dt,
            zero_phase=zero_phase,
            first_phase=first_phase,
            fixed_frequency=fixed_frequency
        ),
        AxisArrays.axes(spectrum)
    )
end

"""
    function ernst(spectrum)

Estimates the zero and first order phase parameters which minimise the
integral of imaginary part of the spectrum.

This implementation is based on suspect.py. See:
https://github.com/openmrslab/suspect/blob/master/suspect/processing/phase.py
"""
function ernst(spectrum::AbstractArray)
    mapslices(
        spec -> single_spectrum_version(spec),
        spectrum,
        dims=ndims(spectrum)
    )
end

function single_spectrum_version(spectrum::AbstractArray)
    np = size(spectrum)[end]
    function residual(ph::Vector{Float64})
        phased = adjust_phase(spectrum, zero_phase=ph[1], first_phase=ph[2])
        sum(imag.(phased))
    end
    intial_x = [0.0, 0.0]
    lower = [-pi, -0.01]
    upper = [pi, 0.25]
    # Minimize residual
    result = optimize(residual, lower, upper, intial_x, NelderMead())
    result.minimizer
end

"""
    function baseline_als(spectrum, lambda::Float64, p::Float64; niter::Int64=10)

Baseline correction based on ALS (Asymmetric Least Square).

Lambda is 2nd derivative constraint, which contributes to the smoothness, while p is
weighting of positive residuals, which affect to the asymmetry.

This implementation is inspired by https://stackoverflow.com/a/29185844/5023889
"""
function baseline_als(spectrum::AbstractArray, lambda::Float64, p::Float64; niter::Int64=10)
    L = size(spectrum)[1]
    x = diff(Matrix{Float64}(I, L, L), dims=2)
    D = sparse(diff(x, dims=2))
    w = ones(L)
    z = nothing
    for i in 1:niter
        W = sparse(diagm(ones(L)))
        Z = W + lambda * (D * transpose(D))
        z = Z \ (w .* spectrum)
        w = (p .* (spectrum > z)) + ((1-p) .* (spectrum < z))
    end
    z
end

function baseline_als(spectrum::AxisArray, lambda::Float64, p::Float64; niter::Int64=10)
    AxisArray(
        baseline_als(spectrum, lambda, p; niter=niter),
        AxisArrays.axes(y)
    )
end
