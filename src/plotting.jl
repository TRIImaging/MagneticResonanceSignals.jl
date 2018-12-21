# MRExperiment is summarized in terms of its loop counters.
@recipe function f(expt::MRExperiment)
    acq = expt.data
    nloop = length(acq[1].loop_counters)
    t = scanner_time(expt)
    t = t .- t[1]
    all_labels = counter_labels(expt)
    labels = []
    title --> "Loop counter summary"
    for i = 1:nloop
        c = [a.loop_counters[i] for a in acq]
        if any(c .!= 0)
            @series begin
                label --> "$(all_labels[i]) (index $i)"
                markershape --> :circle
                markersize --> 1
                t, c
            end
        end
    end
end

# Color map similar to the one which comes with Felix NMR
const RGBN0f8 = RGB{Colors.N0f8}
const felix_colors = [
    RGBN0f8(0.0,0.0,1.0)  ,
    RGBN0f8(0.063,0.0,1.0),
    RGBN0f8(0.247,0.0,1.0),
    RGBN0f8(0.749,0.0,1.0),
    RGBN0f8(1.0,0.0,0.749),
    RGBN0f8(1.0,0.0,0.498),
    RGBN0f8(1.0,0.0,0.247),
    RGBN0f8(1.0,0.0,0.0)  ,
    RGBN0f8(1.0,0.247,0.0),
    RGBN0f8(1.0,0.498,0.0),
    RGBN0f8(1.0,0.561,0.0),
    RGBN0f8(1.0,0.627,0.0),
    RGBN0f8(1.0,0.749,0.0),
    RGBN0f8(1.0,0.812,0.0),
    RGBN0f8(1.0,0.871,0.0),
    RGBN0f8(1.0,1.0,0.063),
    RGBN0f8(1.0,1.0,0.125),
    RGBN0f8(1.0,1.0,0.188),
    RGBN0f8(1.0,1.0,0.247),
    RGBN0f8(1.0,1.0,0.373),
    RGBN0f8(1.0,1.0,0.498),
    RGBN0f8(1.0,1.0,0.561),
    RGBN0f8(1.0,1.0,0.624),
    RGBN0f8(1.0,1.0,0.686),
    RGBN0f8(1.0,1.0,0.749),
    RGBN0f8(1.0,1.0,0.812),
    RGBN0f8(1.0,1.0,0.914),
    RGBN0f8(1.0,1.0,0.882),
]
