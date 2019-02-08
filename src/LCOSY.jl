"""
A standard L-COSY experiment with (num_averages × nsamp_t1) acquisitions,
possibly with reference scans included.
"""
struct LCOSY
    # Metadata
    t1          # Indirect time axis
    echo_time   # Minimum echo time (first T1 increment)

    # Indices into underlying acqusition list
    ref_scans::Vector{Int}
    lcosy_scans::Matrix{Int}  # num_averages × length(t1)

    # Raw acquisitions
    acquisitions
end

standard_metadata(l::LCOSY) = standard_metadata(l.acquisitions)

function Base.show(io::IO, lcosy::LCOSY)
    println(io, """
                LCOSY experiment:
                  t1 = $(lcosy.t1)
                  size(lcosy_scans) = $(size(lcosy.lcosy_scans))
                  length(ref_scans) = $(length(lcosy.ref_scans))""")
    show(io, lcosy.acquisitions)
end


"""
    simple_averaging(spectro_expt)

Simple channel combination and averaging for spectroscopic data acquisition.
"""
function simple_averaging(lcosy::LCOSY; downsample=1)
    acqs = lcosy.acquisitions
    # Use reference scans if possible to figure out channel combination
    # weights; if not, use the actual data (which has worse SNR because it's
    # probably water-suppressed)
    combiner_inds = lcosy.ref_scans
    if isempty(combiner_inds)
        # TODO: Put this logic in pca_channel_combiner ?
        combiner_inds = vec(lcosy.lcosy_scans)
    end
    combiner = pca_channel_combiner(sampledata(acqs, i) for i in combiner_inds)

    # Hmm. Calling sampledata to initialize this is kinda ugly...
    fid1 = combiner(sampledata(acqs, lcosy.lcosy_scans[1,1], downsample=downsample))
    t2 = AxisArrays.axes(fid1, Axis{:time}).val

    num_averages = size(lcosy.lcosy_scans, 1)
    nsamp_t1 = size(lcosy.lcosy_scans, 2)
    signal = AxisArray(zeros(eltype(fid1), length(t2), nsamp_t1),
                       Axis{:time2}(t2), Axis{:time1}(lcosy.t1))
    for i=1:nsamp_t1
        scans_for_avg = lcosy.lcosy_scans[:,i]
        fid = mean(combiner.(sampledata.(Ref(acqs), scans_for_avg, downsample=downsample)))
        signal[:,i] = fid
    end

    signal
end


