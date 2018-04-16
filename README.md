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
