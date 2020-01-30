using Documenter, MagneticResonanceSignals

makedocs(;
    modules=[MagneticResonanceSignals],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/TRIImaging/MagneticResonanceSignals.jl/blob/{commit}{path}#L{line}",
    sitename="MagneticResonanceSignals.jl",
    authors="Chris Foster <chris42f@gmail.com>"
)

deploydocs(;
    repo="github.com/TRIImaging/MagneticResonanceSignals.jl",
    push_preview=true
)
