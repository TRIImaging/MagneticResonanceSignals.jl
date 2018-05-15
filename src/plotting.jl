"""
    summarize_twix(expt)

Produce a visual summary of twix data.  For now, this is a summary of loop
counter variation.
"""
function summarize_twix(expt::MRExperiment)
    acq = expt.data
    nloop = length(acq[1].loop_counters)
    t = timestamp(expt)
    t = t .- t[1]
    labels = []
    for i = 1:nloop
        c = [a.loop_counters[i] for a in acq]
        if any(c .!= 0)
            plot(t, [a.loop_counters[i] for a in acq], ".-")
            push!(labels, "index $i ($(TriMRS.counter_labels(expt)[i]))")
        end
    end
    legend(labels)
    title("Loop counter summary")
    nothing
end

