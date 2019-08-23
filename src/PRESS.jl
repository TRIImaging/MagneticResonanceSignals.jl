"""
A standard PRESS experiment with num_averages acquisitions,
possibly with navigator and reference scans included.
"""
struct PRESS
    # Metadata
    echo_time # Echo time

    # Indices into underlying acqusition list
    ref_scans::Vector{Int}
    press_scans::Matrix{Int}

    navigator::Vector{Int}

    # Raw acquisitions
    acquisitions
end

standard_metadata(p::PRESS) = standard_metadata(p.acquisitions)

function Base.show(io::IO, press::PRESS)
    println(io, """
                PRESS experiment:
                  size(press_scans) = $(size(press.press_scans))
                  length(ref_scans) = $(length(press.ref_scans))
                Navigator experiment:
                  length(navigator) = $(length(press.navigator))""")
    show(io, press.acquisitions)
end
