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
