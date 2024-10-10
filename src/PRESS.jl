struct PRESS
    # Metadata
    echo_time # Echo time

    # Indices into underlying acqusition list
    ref_scans::Vector{Int}
    press_scans::Matrix{Int}

    navigator::Vector{Int}

    # Raw acquisitions
    acquisitions

    cycle_length
end

standard_metadata(p::PRESS) = standard_metadata(p.acquisitions)

"""
A standard Point Resolved Spectroscopy (PRESS) experiment with `num_averages`
acquisitions, possibly with navigator and reference scans included.

This is implemented as "single voxel spectroscopy" and is the standard product
sequence for in vivo MR spectroscopy on Siemens scanners as of early 2020.
"""
function PRESS(
    echo_time,
    ref_scans::Vector{Int},
    press_scans::Matrix{Int},
    navigator::Vector{Int},
    acquisitions
)
    PRESS(
        echo_time,
        ref_scans,
        press_scans,
        navigator,
        acquisitions,
        count_cycles(acquisitions)
    )
end

function Base.show(io::IO, press::PRESS)
    println(io, """
                PRESS experiment:
                  size(press_scans) = $(size(press.press_scans))
                  length(ref_scans) = $(length(press.ref_scans))
                Navigator experiment:
                  length(navigator) = $(length(press.navigator))""")
    show(io, press.acquisitions)
end

function extract_fids(press::PRESS; downsample=1)
    acqs = press.acquisitions
    # Use reference scans if possible to figure out channel combination
    # weights; if not, use the actual data (which has worse SNR because it's
    # probably water-suppressed)
    combiner_inds = press.ref_scans
    if isempty(combiner_inds)
        # TODO: Put this logic in pca_channel_combiner ?
        combiner_inds = vec(press.press_scans)
    end
    combiner = pca_channel_combiner(sampledata(acqs, i) for i in combiner_inds)

    # Hmm. Calling sampledata to initialize this is kinda ugly...
    fid1 = combiner(sampledata(acqs, press.press_scans[1,1], downsample=downsample))
    t = AxisArrays.axes(fid1, Axis{:time}).val
    num_averages = length(press.press_scans)
    phase_cycle = mod1.(1:num_averages, press.cycle_length)

    signal = AxisArray(zeros(eltype(fid1), length(t), num_averages),
                       Axis{:time}(t),
                       Axis{:phase_cycle}(phase_cycle))
    for i=1:num_averages
        fid = combiner(sampledata(acqs, press.press_scans[i], downsample=downsample))
        signal[:,i] = fid
    end
    signal
end

function simple_averaging(press::PRESS; downsample=1)
    fids = extract_fids(press, downsample=downsample)
    simple_averaging(fids)
end

"""
    spectrum(press::PRESS,
             win=t->sinebell(t, pow=2),,
             t1pad=4,
             downsample=1)

Compute spectrum from press data with processing parameters as follows.
   * Simple averaging
   * T: Sine bell squared window, 4x zero padded
"""
function spectrum(press::PRESS;
                  win=t->sinebell(t, pow=2),
                  tpad=4,
                  downsample=1)
    signal = simple_averaging(press, downsample=downsample)
    # Apply sine bell squared windows to signal, as in TRI Felix workflow
    apply_window!(signal, Axis{:time}, win)
    signal = zeropad(signal, Axis{:time}, tpad)
    spectrum(signal)
end
