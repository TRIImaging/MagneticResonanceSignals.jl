# TriMRS

Analysis tools for Magnetic Resonance Spectroscopy data, similar to the python
library [suspect](https://github.com/openmrslab/suspect).  In scope, for now,
are:

  * File input and output
  * Basic signal processing
  * Classifiers and feature engineering

While we initially rely on some of the suspect functionality, `TriMRS` includes
tooling specific to what we're working on at TRI (particularly 2D MRS) and is
also written in julia which is much nicer for this kind of numerical work.

## Quick start

Here's an example of how you can load COSY data from Siemens TWIX format,
convert it into a spectrum and view that spectrum:

```julia
using TriMRS, AxisArrays, Unitful

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
using TriMRS, AxisArrays

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

## Installation

To use `TriMRS`, you'll need to have a version of python with the suspect
library installed. I suggest:
  1. Download the anaconda python distribution
  2. Create a new python environment called "julia"
  3. Install suspect using `pip install suspect`
  4. Activate the julia environment with something like `conda activate julia`,
     and precompile `PyCall` from julia within this environment, using
     `Pkg.add("PyCall")`

While you're at it, you should probably make sure `PyPlot.jl` will work nicely
in your python environment using `conda install matplotlib`.


## TriMRS Tools and Tool Packaging

Speculative plan:

Individual tools for end users reside in subdirectories of the `run` directory.
`TriMRS` contains some simple packaging scripts which can package pure julia
code into a zip file which can be distributed to users.

### Tool source code

* Tools reside in `run/toolname` directories which include:
  - `main.jl` which is the main entry point script
  - `REQUIRE` which defines package requirements as usual

### Tool packaging / package structure

* Running `tools/makepackage.jl tooldir` should create a zip file containig the
  package structure, including
  - A launcher of some kind which can find julia.exe and run the script.  This
    can also set an environment variable or command line argument to provide
    some other indication that the script is being run in release mode.
  - A VERSION file, specifying the TriMRS git version and some record of the
    build process.  Also enure that the git versions of packages are recorded
    somewhere.

For installation, there's two possible implementations:
1. We recursively harvest all the required julia packages and distribute them
   in a zip file.  At packaging time, this requires using the union of REQUIRE
   files from TriMRS and the tool, setting `JULIA_PKGDIR` to a clean scratch
   dir, and zipping up all the code which appears there.  At runtime we can
   then set `JULIA_PKGDIR` to pick these up.  If there's no binary
   dependencies, this is a sure way to keep library dependencies under control.
   For binary dependencies, we might run into big problems.  We'd need to
   ensure the package dir is portable and relocatable enough.
2. Ship a `REQUIRE` file and rely on `Pkg` to resolve this on the user machine
   at install time (get launcher to autodetect whether an install step is
   required?).  The `REQUIRE` file should be "cooked" to exactly pin down the
   package versions - `DeclarativePackages` style.  Undoubtably this will cause
   extra woes at install time, but it would remove some binary dependency
   problems on different platforms.

