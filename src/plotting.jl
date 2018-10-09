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
                t, c
            end
        end
    end
end
