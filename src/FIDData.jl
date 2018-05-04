"""
    struct SpectroData{T,N}

A container for an `Array{T,N}` of time domain MR spectroscopy data.

This data structure assume the experiment densely samples the parameter space
(eg, the t1 increments for COSY).  More general experiments can be represented
using the `MRExperiment` type.
"""
struct SpectroData{T,N}
    data::Array{T,N}
    f0::Float64
    dt::SVector{2,Float64}
    te::Float64
    ppm0::Float64
    protocol_name::String
    metadata
end

SpectroData(data, f0, dt; te=0.0, ppm0=4.7, protocol_name="", metadata=Dict()) =
    SpectroData(data, f0, SVector{2,Float64}(dt), te, ppm0, protocol_name, metadata)

function SpectroData(expt::MRExperiment)
    seqfile = expt.metadata["tSequenceFileName"]
    if seqfile != "%CustomerSeq%srcosy"
        throw(ArgumentError("Cannot harvest spectro from unrecognized sequence: $seqfile"))
    end
    # FID sampling period in ns
    dt2 = 1e-9 * expt.metadata["sRXSPEC.alDwellTime[0]"]
    # TODO: Is this is stored in μHz?
    f0  = 1e-6 * expt.metadata["sTXSPEC.asNucleusInfo[0].lFrequency"]
    # Ugh. srcosy stashes the t1 increment in the special card WIP block
    # params (in ms). This appears to be the only place it occurs in the
    # metadata.
    dt1 = 1e-3 * expt.metadata["sWipMemBlock.adFree[1]"]
    # TODO: Unsure whether the echo time te is meaningful for srcosy...
    # suspect.py thinks it's in μs
    te  = 1e-6 * expt.metadata["alTE[0]"]
    protocol_name = expt.metadata["tProtocolName"]

    # Load experimental data into a big block
    # First validate that all experimental data is present
    indexed_acqs = Dict((1 + a.loop_counters[7], 1 + a.loop_counters[2])=>a for (i,a) in enumerate(expt.data))
    t1_indmin,t1_indmax   = extrema(i[1] for i in keys(indexed_acqs))
    avg_indmin,avg_indmax = extrema(i[2] for i in keys(indexed_acqs))
    @assert t1_indmin == 1 && avg_indmin == 1

    # FIXME: For efficiency, would be better to have the first dimension as the
    # FID dimension, shouldn't we?
    data = zeros(eltype(expt.data[1].data), (avg_indmax, t1_indmax, size(expt.data[1].data)...))
    for t1_ind = t1_indmin:t1_indmax
        for avg_ind = avg_indmin:avg_indmax
            # The conj here is for compatibility with the way that suspect.py
            # reads the data.  Not sure what this is for yet.
            data[avg_ind,t1_ind,:,:] .= conj.(indexed_acqs[(t1_ind,avg_ind)].data)
        end
    end
    SpectroData(data, f0, [dt1,dt2], te=te, protocol_name=protocol_name)
end

function Base.show(io::IO, fids::SpectroData)
    data = fids.data
    print(io, """
          SpectroData with data of shape $(size(data)):
              protocol:
                 $(fids.protocol_name)
              fid acquisition:
                 fid length   = $(size(data,4))
                 dt           = $(fids.dt) s
                 f0           = $(fids.f0) Hz
                 n_t1         = $(size(data,2))
                 n_t2         = $(size(data,4))
                 num_channels = $(size(data,3))
                 num_average  = $(size(data,1))
              auxiliary:
                 ppm0             = $(fids.ppm0)
                 length(metadata) = $(length(fids.metadata))
          """
    )
end

"""
    get_fid(fids, t1_index, repetition, channel)

Get the time domain FID for a given `repetition`, `t1_index` and `channel`.
"""
function get_fid(fids::SpectroData, t1_index, repetition, channel)
    fids.data[repetition,t1_index,channel,:]
end

"""
    fid_length(fids)

Return the number of samples in each FID stored in `fids`.
"""
fid_length(fids::SpectroData) = size(fids.data)[end]

"""
    hertz_to_ppm(fids, f)

Converts a frequency in Hz to a relative frequency in PPM.
"""
hertz_to_ppm(fids::SpectroData, f) = fids.ppm0 - f/fids.f0

"""
    ppm_to_hertz(fids, ppm)

Converts a relative frequency in PPM to a frequency in Hz.
"""
ppm_to_hertz(fids::SpectroData, ppm) = (fids.ppm0 - ppm)*fids.f0

"""
    time_axis(fids, dim=2)

Get the time for the FID samples, starting from 0 s
"""
time_axis(fids::SpectroData, dim=2) = fids.dt[dim]*(0:fid_length(fids)-1)

"""
    frequency_axis(fids, dim=2; pad=1)

Get the frequency axis for the FID samples, in Hz, when fourier transformed and shifted.

Set `pad` to a positive integer to get the frequency axis for a padded FID of
length `pad*fid_length(fids)`.
"""
function frequency_axis(fids::SpectroData, dim=2; pad=1)
    N = pad*fid_length(fids)
    df = 1/fids.dt[dim]
    df*((0:N-1)/N - 0.5)
end

"""
    frequency_axis_ppm(fids; pad=1)

Get the frequency axis for FID samples, in ppm
"""
frequency_axis_ppm(fids::SpectroData, dim=2; pad=1) = hertz_to_ppm.(fids, frequency_axis(fids,dim, pad=pad))


