_axisdim(a, ax) = axisdim(a, ax)
_axisdim(a, ax::Integer) = ax

function _makewin(fid, axis, windowfunc)
    dim = _axisdim(fid, axis)
    dimlen = size(fid, dim)
    w = windowfunc.((0:dimlen-1)/dimlen)
    # Reshape to broadcast `w` only along time dimension
    windowshape = ntuple(i->i==dim ? dimlen : 1, ndims(fid))
    reshape(w, windowshape...)
end

"""
Apply `windowfunc` over the dimensionless time range `(0:tlen-1)/tlen)` of
`fid` along dimension `axis` which can be an `Axis` or `Integer`.

See also `apply_window`.
"""
function apply_window!(fid::AxisArray, axis, windowfunc)
    w = _makewin(fid, axis, windowfunc)
    fid .*= w
    fid
end

"""
    apply_window(signal, axis1=>win1, axis2=>win2, ...)

Apply window functions `win1` along `axis1`, `win2` along `axis2`, etc.  The
windows should be functions over the dimensionless time domain `0..1`; the axes
should be of type `AxisArrays.Axis`.

# Background

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
function apply_window(fid::AxisArray, windows::Pair...)
    fid = copy(fid)
    axis,winfunc = windows[1]
    for (axis,winfunc) in windows
        apply_window!(fid, axis, winfunc)
    end
    fid
end

"""
    sinebell(t; skew=1, pow=1)

The sinebell window on the dimensionless time range `t ∈ 0..1`.

Use `pow=2` for sinebell squared. Setting the `skew` parameter to something
other than the default of `1.0` gives a skewed sinebell window, as in Felix NMR.
"""
function sinebell(t::Number; skew=1.0, pow=1.0)
    # Guess at the Felix parameterization via inspection of the window in the
    # UI; seen via "Open and Process"->"Window"->"Real time"
    sin(pi*t^skew)^pow
end

