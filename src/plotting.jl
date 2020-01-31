using PrettyTables

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

filter_zero_counters(counter_vals,col) = any(counter_vals[:,col] .!= 0)

"""
    summarize(expt::MRExperiment)

Print detailed textural summary of the MR experiment. `kwargs` are passed to
`PrettyTables.pretty_table()`, for example, to show loop counters which are all
zero, add the keyword argument `filters_col=()`.
"""
function summarize(io::IO, expt::MRExperiment; kwargs...)
    kwargs = merge((crop=:horizontal, filters_col=(filter_zero_counters,),), kwargs)
    counter_names = collect(fieldnames(LoopCounters))
    counter_vals = zeros(Int, length(expt.data), length(counter_names))
    for (i,acq) in enumerate(expt.data)
        counter_vals[i,:] = acq.loop_counters
    end
    pretty_table(io, counter_vals, counter_names; kwargs...)
end

function summarize(expt::MRExperiment; kwargs...)
    summarize(stdout, expt; kwargs...)
end

# Color map similar to the one which comes with Felix NMR
const RGBN0f8 = RGB{Colors.N0f8}

"""
A popular color map for multidimensional NMR data as defined in Felix NMR
"""
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


# FIXME: Type piracy; should get this into AxisArrays instead!
using RecipesBase

@recipe function plot(a::AxisArray)
    ax1 = AxisArrays.axes(a,1)
    xlabel --> AxisArrays.axisname(ax1)
    if ndims(a) == 1
        ax1.val, a.data
    else
        ax2 = AxisArrays.axes(a,2)
        # Categorical axes print as a set of labelled series
        if axistrait(ax2) === Categorical
            for i in eachindex(ax2.val)
                @series begin
                    label --> "$(AxisArrays.axisname(ax2)) $(ax2.val[i])"
                    ax1.val, a.data[:,i]
                end
            end
        else
            # Other axes as a 2D array
            ylabel --> AxisArrays.axisname(ax2)
            seriestype --> :heatmap
            ax1.val, ax2.val, a.data
        end
    end
end

