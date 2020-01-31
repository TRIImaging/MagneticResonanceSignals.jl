# MagneticResonanceSignals.jl

This library was developed with the intent to flexibly process data from
unusual and bespoke magnetic resonance (MR) sequences.  Similar to the python
library [suspect](https://github.com/openmrslab/suspect), the focus has been on
spectroscopy, so the higher level functionality is specific to spectroscopy.

However, rather than being limited to spectroscopy, this library tries to
provide rich and general access to the raw data in a way which reflects an
arbitrary MR experiment. In particular, it provides a reader for the raw
Siemens "twix" format and some nascent facilities to abstract over that format
with the capabilities and limitations of the physical experiment in mind.

In a way, this makes the library partly comparable to the much larger project
[ISMRMRD](https://ismrmrd.github.io/) and we should arguably have a reader for
ISMRMRD format here. However, ISMRMRD is an extra layer of conversion away from
the raw data and is somewhat imaging-focused (this is both good and bad).

## Installation

To install, issue the following command from Julia's [package prompt](https://docs.julialang.org/en/v1/stdlib/Pkg/index.html).

```
pkg> add https://github.com/TRIImaging/MagneticResonanceSignals.jl
```

## Table of Contents

```@contents
Pages = ["guide.md", "reference.md"]
```

