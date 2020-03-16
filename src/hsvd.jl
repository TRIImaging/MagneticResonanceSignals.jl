
"""
    hsvd(fid, rank)

Use the Hankel singular value decomposition method for fitting a sum of
exponential signals of the form

    xₙ = Σₖ Aₖ zₖⁿ

to compute the ampltudes Aₖ and complex-valued poles zₖ. Any poles with |zₖ| >
1 are discarded to avoid numerical instability during the fit. A tuple of poles,
amplitudes and the exponential basis (z,A,basis) is returned.

The discrete-time and continuous time signals are related by

    sₙ =  Aₖ zₖⁿ  =  Aₖ exp((-bₖ + iωₖ) * tₙ)

or

    zₖ  =  exp((-bₖ + iωₖ) * Δt)

where ωₖ is an angular frequency and bₖ the decay rate in Hz.

Ref. to NMR literature: Barkhuijsen et al., "Improved Algorithm for Noniterative
Time-Domain Model Fitting to Exponentially Damped Magnetic Resonance Signals",
J. Mag. Res., (1987) https://doi.org/10.1016/0022-2364(87)90023-0

More broadly these techniques seem to come under the title "Singular Spectrum
analysis".
"""
function hsvd(fid, rank)
    # In the code below we attempt to use the same notation as the paper.
    # Construct the Hankel matrix
    N = length(fid)
    L = N÷2
    M = N-L
    X = zeros(ComplexF64, L, M)
    for i = 1:M
        X[:, i] .= fid[i:i+L-1]
    end

    # Form a low-rank approximation to the signal basis by truncating the SVD U
    # factor to the given rank.
    hsvd = svd(X)
    Xl = hsvd.U[:, 1:rank]

    # As described in the paper, each row of Xl is the row below multiplied by
    # some matrix Zp, so we can compute Zp with a linear by solving the
    # overdetermined system `Ub*Zp = Ut` as a least squares problem:
    Ub = Xl[1:end-1, :]
    Ut = Xl[2:end, :]
    Zp = Ub \ Ut

    # The eigen decomposition of Zp now gives the eigenvalues as the poles
    Zeig = eigen(Zp)
    Zeig.values
end


"""
    hsvd_water_suppression(fid; dt = 0.0008, water_center_freq=0.0,
                           bandwidth=100.0, hsvd_rank=50)

Use HSVD to suppress a spectral region.
"""
function hsvd_water_suppression(fid::AbstractArray; dt = 0.0008, water_center_freq=0.0,
                                bandwidth=100.0, hsvd_rank=50)
    zs0 = hsvd(fid, hsvd_rank)

    # Filter out any exponentially growing components. These can occur if a
    # naive truncation-based frequency domain downsampling of the time domain
    # signal is used. (For example this seems to be the default on Siemens
    # scanners when using the "remove oversampling" option.)
    zs = zs0[abs.(zs0) .< 1]

    # Generate a basis from the components and fit to it to determine the
    # amplitudes of the various signal components.
    basis = [zs[i]^n for n=0:length(fid)-1, i=1:length(zs)]
    A = basis \ fid

    # Compute MR frequencies of components
    frequencies = imag(log.(zs))/dt

    # Assume all signal within some spectral bandwidth of water centre frequency
    water_components = abs.(frequencies .- water_center_freq) .< bandwidth

    water = basis[:,water_components] * A[water_components]

    fid .- water
end

function hsvd_water_suppression(fid::AxisArray; dt = 0.0008, water_center_freq=0.0,
                                bandwidth=100.0, hsvd_rank=50)
    signal_ax = AxisArrays.axes(fid)
    AxisArray(hsvd_water_suppression(fid.data;
                                     dt=dt,
                                     water_center_freq=water_center_freq,
                                     bandwidth=bandwidth,
                                     hsvd_rank=hsvd_rank),
              signal_ax)
end
