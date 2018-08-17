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

export sinebell

"""
    sinebell(t, skew, n)

Skewed sine bell window, as in Felix NMR (zero phase shift).

In the Felix UI, the window function can be seen via
"Open and Process"->"Window"->"Real time"
which allows for interactive editing of the window.
"""
function sinebell(t, skew, n)
    # Educated guess at the Felix parameterization.
    sin(pi*t.^skew)^n
end

end
