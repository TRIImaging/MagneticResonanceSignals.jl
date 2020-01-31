# How-to Guide

## Loading file data

Raw data:

* `load_twix` — load Siemens raw scanner `"meas_*.dat"` "twix" format, as
  produced by the twix exporter program available at clinical sites with a
  Siemens IDEA licence.

* `mr_load` — load raw scanner data and recognize the sequence, wrapping in
  sequence-specific metadata.

Spectroscopy:

* `load_rda`, `save_rda` — simple support for the Siemens ".rda" processed
  spectroscopy format.
* `save_nmrpipe` — save spectroscopy data to
  [NMRPipe](https://www.ibbr.umd.edu/nmrpipe/) format. We have found this
  helpful for importing into mestrelab's
  [MNova](https://mestrelab.com/software/mnova/) NMR processing software.
* `save_felix` — save spectroscopy data to [Felix NMR](http://www.felixnmr.com/)
  ".dat" format.

## Converting Siemens raw data to Felix format

TODO

## Processing 2D L-COSY spectroscopy

Here's an example of how you can load L-COSY data from Siemens TWIX format,
convert it into a spectrum and view that spectrum:

```julia
using MagneticResonanceSignals, AxisArrays, Unitful

cosy = mr_load("meas_MID00417_FID85233_svs_lcosy.dat")

# High level interface: this does the whole spectral conversion for you using
# simple averaging.  You can set the windows here if you like.
spec = spectrum(cosy)

# Plot the absolute value of the spectrum
using Plots
pyplot()
getaxis(s, n) = ustrip.(uconvert.(u"Hz", AxisArrays.axes(s, Axis{n}).val))
f1 = getaxis(spec, :freq1)
f2 = getaxis(spec, :freq2)
contour(f2, reverse(f1), Matrix(transpose(log.(abs.(spec)))); levels=-10:0.3:-3,
        seriescolor=cgrad(felix_colors), clims=(-10,-3),
        background_color=:black, aspectratio=1.0,
        xlabel="F2 (Hz)", ylabel="F1 (Hz)",
        xticks=-1000:100:1000, yticks=-1000:100:1000,
        xlim=[-200,550], ylim=[-200,550])
```

Here's an example of how you can convert to Felix format:

```julia
using MagneticResonanceSignals, AxisArrays

cosy = mr_load("meas_MID00417_FID85233_svs_lcosy.dat")
signal = simple_averaging(cosy, downsample=2)

# Extract some metadata required by the felix format
frequency = standard_metadata(cosy).frequency
f1_bandwidth = 1.0/step(AxisArrays.axes(signal, Axis{:time1}).val)
f2_bandwidth = 1.0/step(AxisArrays.axes(signal, Axis{:time2}).val)

save_felix("felix_input.dat", signal; bandwidth=(f2_bandwidth, f1_bandwidth), frequency=frequency)
```

Here's an example of how to do the steps in `spectrum(cosy)`, with the
averaging and windowing written out explicitly.

```julia
signal = simple_averaging(cosy)

# Apply sine bell squared windows to signal, as in TRI Felix workflow
apply_window!(signal, Axis{:time2}, t->sinebell(t, pow=2, skew=0.3))
apply_window!(signal, Axis{:time1}, t->sinebell(t, pow=2))

# Add zero padding here
signal = zeropad(signal, Axis{:time1}, 4)

# Compute spectrum from time domain signal
spec = spectrum(signal)
```

