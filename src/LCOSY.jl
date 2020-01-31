struct LCOSY
    # Metadata
    t1          # Indirect time axis
    echo_time   # Minimum echo time (first T1 increment)

    # Indices into underlying acqusition list
    ref_scans::Vector{Int}
    lcosy_scans::Matrix{Int}  # num_averages × length(t1)

    # Raw acquisitions
    acquisitions

    cycle_length
end

standard_metadata(l::LCOSY) = standard_metadata(l.acquisitions)

"""
An L-COSY experiment with (`num_averages` × `nsamp_t1`) acquisitions, possibly
with reference scans included.

The L-COSY pulse sequence is described in:

* Thomas, M. Albert, et al. "Localized two‐dimensional shift correlated MR
  spectroscopy of human brain." Magnetic Resonance in Medicine 46.1 (2001): 58-67.
* Thomas, M. Albert, et al. "Evaluation of two‐dimensional L‐COSY and JPRESS
  using a 3 T MRI scanner: from phantoms to human brain in vivo." NMR in
  Biomedicine 16.5 (2003): 245-251.
"""
function LCOSY(
  t1, echo_time, ref_scans::Vector{Int}, lcosy_scans::Matrix{Int}, acquisitions
)
    LCOSY(
        t1, echo_time, ref_scans, lcosy_scans, acquisitions, count_cycles(acquisitions)
    )
end

function Base.show(io::IO, lcosy::LCOSY)
    println(io, """
                LCOSY experiment:
                  t1 = $(lcosy.t1)
                  size(lcosy_scans) = $(size(lcosy.lcosy_scans))
                  length(ref_scans) = $(length(lcosy.ref_scans))""")
    show(io, lcosy.acquisitions)
end

"""
    extract_fids(lcosy::LCOSY; downsample=1)

Extract raw fid from LCOSY experiment and apply channel combination
"""
function extract_fids(lcosy::LCOSY; downsample=1)
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
    phase_cycle = mod1.(1:num_averages, lcosy.cycle_length)

    nsamp_t1 = size(lcosy.lcosy_scans, 2)
    signal = AxisArray(zeros(eltype(fid1), length(t2), num_averages, nsamp_t1),
                       Axis{:time2}(t2),
                       Axis{:phase_cycle}(phase_cycle),
                       Axis{:time1}(lcosy.t1))
    for i=1:nsamp_t1
        for j=1:num_averages
            fid = combiner(sampledata(acqs, lcosy.lcosy_scans[j,i], downsample=downsample))
            signal[:,j,i] = fid
        end
    end
    signal
end

"""
    simple_averaging(spectro_expt)

Simple channel combination and averaging for spectroscopic data acquisition.

Note that this uses a simple mean to combine acquisitions across the phase
cycling dimension; it does no frequency alignment or other calibration.
"""
function simple_averaging(lcosy::LCOSY; downsample=1)
    fids = extract_fids(lcosy, downsample=downsample)
    simple_averaging(fids)
end


"""
    spectrum(lcosy::LCOSY,
             win1=t->sinebell(t, pow=2),
             win2=t->sinebell(t, skew=0.3, pow=2),
             t1pad=4)

Compute spectrum from lcosy data with "standard" L-COSY processing parameters
as have traditionally been used by Mountford et. al.
   * Simple averaging
   * T2: skewed sine bell squared window, skew=0.3
   * T1: Sine bell squared window, 4x zero padded
"""
function spectrum(lcosy::LCOSY;
                  win1=t->sinebell(t, pow=2),
                  win2=t->sinebell(t, skew=0.3, pow=2),
                  t1pad=4)
    signal = simple_averaging(lcosy)
    # Apply sine bell squared windows to signal, as in TRI Felix workflow
    apply_window!(signal, Axis{:time2}, win2)
    apply_window!(signal, Axis{:time1}, win1)
    signal = zeropad(signal, Axis{:time1}, t1pad)
    spec = spectrum(signal)

    # TODO: Flip freq1 axis.
    # TODO: Figure out why we need this...
    #freq1 = AxisArrays.axes(s, Axis{:freq1})
    #freq2 = AxisArrays.axes(s, Axis{:freq2})

    spec
end
