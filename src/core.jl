# Core abstractions for the package

@unit ppm "ppm" PartsPerMillion 1//1000000 false

Unitful.register(TriMRS)

"""
4.7 is a chosen nominal chemical shift of water relative to TMS.  Note that
this is only approximate because the true shift can vary based on pH,
temperature, etc and you should calibrate your spectral axes against known
metabolites.
"""
const _water_tms_offset = 4.7u"ppm"

struct MRMetadata
    protocol_name    # Name of sequence parameter set
    sequence_name    # Name of MR sequence code
    software_version # Version of spectrometer software
    device_id        # Device identifier: (manufacturer, model_name, serial)
    ref_epoch        # Epoch of localizer image
    frequency        # Spectrometer frequency (TODO: or frequencies for MNO?)
end

"""
Extract standard MR metadata about an experiment
"""
function standard_metadata
end

"""
    mr_load(data)

High level function for loading MR `data` and recognizing which experiment was
run. The returned object describes the experimental conditions and acquisition
schedule which can be used during data processing.  `data` may be a file name,
`IO` stream, or a data structure describing raw acquisition data, for example,
Siemens Twix.

If the experiment is not recognized, throw an exception.
"""
mr_load(filename::String, args...; kws...) = open(io->mr_load(io, args...; kws...), filename)

# TODO: A magic number system to figure out what to load...
mr_load(io::IO, args...; kws...) = mr_load(load_twix(io, args...; kws...))

"""
    sampledata(expt, index; downsample=1)

Return the acquired data from `expt` at a given acqusition `index`.  If
`downsample>1`, the data will be subsampled by the given rate by truncating the
tails of the signal in the Fourier spectral domain. This has the effect of
removing noise by filtering away irrelevant high and low frequency components.
"""
function sampledata
end

