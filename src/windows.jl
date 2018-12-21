"""
A module containing some unusual windowing functions commonly used in MR work.

For the purposes of spectroscopy, the MR signal is generally an oscillating
decaying signal in the time domain, with different metabolites having different
decay constants. When computing a spectrum with a simple Fourier transform, one
may window the time domain data to emphasize one metabolite or another in the
resulting spectrum. (Spatially resolved spectroscopy involves some kind of MR
echo so the initial part of the signal *may* be increasing, but the this doesn't
affect the irreversible decay mechanisms.)

For *qualitative* exploration of the spectra, one may therefore want to choose
out of several windowing functions with convenient parametric forms. Note that
for *quantitative* measurement of metabolite concentration, windowing distorts
the relative peak volumes and it's probably better to choose a time domain
fitting method.

Note that these MR-specific reasons are subtly different - and apply in addition
to - the generic signal processing reasons for time domain windowing.
"""
module MRWindows

using AxisArrays

export sinebell

"""
Apply `windowfunc` over the dimensionless time range `(0:tlen-1)/tlen)` of
`fid`.
"""
function apply_window!(fid::AxisArray, windowfunc)
    dim = axisdim(fid, Axis{:time})
    t = AxisArrays.axes(fid, Axis{:time}).val
    w = windowfunc.((0:length(t)-1)/length(t))
    # Reshape to broadcast `w` only along time dimension
    windowshape = ntuple(i->i==dim ? length(t) : 1, ndims(fid))
    w = reshape(w, windowshape...)
    fid .*= w
    fid
end

"""
    sinebell(fid; skew, n)

Apply a skewed sine bell window over the full time range of `fid`. This should
be equivalent to the skewed sinebell window with zero phase shift parameter
from the Felix NMR software.
"""
function sinebell(fid; skew, n)
    apply_window!(copy(fid), (t)->_sinebell(t, skew, n))
end

function _sinebell(t, skew, n)
    # Guess at the Felix parameterization via inspection of the window in the
    # UI; seen via "Open and Process"->"Window"->"Real time"
    sin(pi*t^skew)^n
end

end
