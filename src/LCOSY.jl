"""
A standard L-COSY experiment with (num_averages × num_t1_incs) acquisitions,
possibly with reference scans included.
"""
struct LCOSY{F,T}
    # Metadata
    frequency::F      # Spectrometer frequency
    dt1::T            # T1 increment size
    # te::T             # Echo time (required??)
    num_t2_samps::Int # Number of samples in direct (T2) direction
    meta::MRMetadata
    metadata_extras

    # Indices into underlying acqusition list
    ref_scans::Vector{Int}
    lcosy_scans::Matrix{Int}  # num_averages × num_t1_incs
end

function Base.show(io::IO, lcosy::LCOSY)
    println(io, """
                LCOSY MR metadata with
                    frequency = $(lcosy.frequency)
                    dt1 = $(lcosy.dt1)
                    size(lcosy_scans) = $(size(lcosy.lcosy_scans))
                    length(ref_scans) = $(length(lcosy.ref_scans))
                    meta = $(lcosy.meta)
                """)
end


"""
    simple_averaging(template, data)

Simple channel combination and averaging for spectroscopic data acquisition.
"""
function simple_averaging(lcosy::LCOSY, twix, downsample=2)

    combiner = pca_channel_combiner(twix.data) # FIXME: cleanup

    t2_ax = AxisArrays.axes(sampledata(twix,1, downsample=downsample), Axis{:time})
    t1_val = (0:num_t1_incs-1)*dt1
    nsamps = length(t2_ax)
    signal = AxisArray(zeros(ComplexF64, nsamps, num_t1_incs),
                       Axis{:time2}(t2_ax.val), Axis{:time1}(t1_val))
    for i=1:num_t1_incs
        scans_for_avg = (i-1)*num_averages .+ (1:num_averages)
        # FIXME: Remove this conj?
        fid = conj.(mean(combiner.(sampledata.(Ref(twix), scans_for_avg))))
        signal[:,i] = fid
    end

    f1_bandwidth = 1.0/dt1
    f2_bandwidth = 1.0/step(t2_ax.val)
end
