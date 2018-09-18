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
    # The name "DwellTime" is probably a stretched analogy with radar signal
    # processing terminology.
    dt2 = 1e-9 * expt.metadata["sRXSPEC.alDwellTime[0]"]
    # This is stored in Hz, but we convert to MHz for convenience in the PPM conversion.
    # TODO: Probably better if we didn't!
    f0  = 1e-6 * expt.metadata["sTXSPEC.asNucleusInfo[0].lFrequency"]
    # Ugh. srcosy stashes the t1 increment in the special card WIP block
    # params (in ms). This appears to be the only place it occurs in the
    # metadata.
    dt1 = 1e-3 * expt.metadata["sWipMemBlock.adFree[1]"]
    # Echo time - will set relative content of different metabolites in the
    # signal, depending on decay rates.
    te  = 1e-6 * expt.metadata["alTE[0]"]
    protocol_name = expt.metadata["tProtocolName"]

    # Load experimental data into a big block
    # First validate that all experimental data is present
    indexed_acqs = Dict((1 + a.loop_counters[7], 1 + a.loop_counters[2])=>a for (i,a) in enumerate(expt.data))
    t1_indmin,t1_indmax   = extrema(i[1] for i in keys(indexed_acqs))
    avg_indmin,avg_indmax = extrema(i[2] for i in keys(indexed_acqs))
    @assert t1_indmin == 1 && avg_indmin == 1

    data = zeros(eltype(expt.data[1].data), (size(expt.data[1].data)..., avg_indmax, t1_indmax))
    for t1_ind = t1_indmin:t1_indmax
        for avg_ind = avg_indmin:avg_indmax
            # FIXME: Figure out what to do with dummy samples at the start of
            # data
            data[:,:,avg_ind,t1_ind] .= indexed_acqs[(t1_ind,avg_ind)].data
        end
    end
    SpectroData(data, f0, [dt1,dt2], te=te, protocol_name=protocol_name, metadata=expt.metadata)
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
                 f0           = $(fids.f0) MHz
                 n_t2         = $(size(data,1))
                 num_channels = $(size(data,2))
                 num_average  = $(size(data,3))
                 n_t1         = $(size(data,4))
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
    fids.data[:,channel,repetition,t1_index]
end

"""
    fid_length(fids)

Return the number of samples in each FID stored in `fids`.
"""
fid_length(fids::SpectroData) = size(fids.data,1)

function MRAxis(fids::SpectroData, dim::Integer; kws...)
    npoints = (dim == 1) ? size(fids.data,4) :
              (dim == 2) ? size(fids.data,1) :
              throw(ArgumentError("COSY has only two dimensions, but dim=$dim was passed"))
    MRAxis(fids.f0, fids.dt[dim], npoints, kws...)
end

