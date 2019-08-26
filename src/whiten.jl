using PyPlot
using TriMRS
using Statistics
using LinearAlgebra
using FFTW

#twix = load_twix("/dmf/tri_services/Facilities/Imaging/mr_data/newcastle_ptsd/Acalar/1/twix/seq-svsse_loc-pcg_te-30_tr-2000.dat")
#twix = load_twix("/dmf/tri_services/Facilities/Imaging/mr_data/newcastle_ptsd/Acalar/1/twix/seq-svsse_loc-acc_te-30_tr-2000.dat")
twix = load_twix("/dmf/tri_services/Facilities/Imaging/mr_data/newcastle_ptsd/Acalar/1/twix/seq-svsse_loc-thal_te-30_tr-2000.dat")

# For noise samples, use the tail of the water suppressed spectra.  This will
# be as noisy as possible!
noise = 100
noise_samples = vcat([ComplexF64.(sampledata(twix,i).data[end-noise+1:end, :]) for i=2:97]...)

signal_samples = ComplexF64.(sampledata(twix,1).data)

# Channel combination based on
#
# "Receive Array Magnetic Resonacne Spectroscopy: Whitened Singular Value
# Decomposition (WSVD) Gives Optimal Bayesian Solution", Rodgers and Robson,
# MRM (2010)
#
# https://doi.org/10.1002/mrm.22230
#
# * Dominant noise is thermal fluctuations in the subject
# * Channel noise assumed to be approximated by multivariate normal

# 1) Compute approximation to noise covariance
#
# By definition, the covariance of a complex random variable Z with mean μ is
# the expectation of the outer product:
#
#    E[(Z-μ) (Z-μ)']
#
# This means that when estimating the covariance from a matrix of *samples*, A,
# of the distribution, Z, we should most naturally store our N samples in the
# *rows* of A, and compute
#
#    cov(A,dims=2) = 1/N (A-μ) * (A-μ)'
#
# However Julia is column-oriented so we store our samples in columns and
# compute
#
#   cov(A) = conj((A-μ)' * (A-μ))
#
# note the conj here!
#
# We aim to construct a weighting matrix W which will post-multiply our signals
# (stored as columns) to produce new channels with noise covariance matrix
# equal to the scaled identity I/2 (this is called a "whitening
# transformation"). This can be achieved using an eigen decomposition:

Σ1 = cov(noise_samples)
E = eigen(Hermitian(Σ1))
W = conj(E.vectors) * Diagonal(@. 1/sqrt(2*E.values))

# 2) Next, we want to use the signal level in these resulting virtual channels
# to compute channel combination coefficient magnitudes and phases. Channels
# with a lot of signal should get large coefficients.
#
# We form our weighted signal as:

s = signal_samples * W

# SVD decomposes the weighted signal s into
#
#   s = U Ψ Vt
#
# where `U` and `Vt` are unitary and Ψ is diagonal.
#
# The signal of interest is the first column of U, corresponding to the largest
# singular value. This may be extracted from s by right-multiplying by the
# first column V₁ of V ≡ Vt':
#
#   s V₁  =  U Ψ (V' V₁)  =  U Ψ e₁  =  U[:,1] * Ψ[1,1]
#
# where we use the fact that V'*V = I to get `e₁ = [1, 0, 0, ...]` which is a
# unit vector and hence selects out the first column of U.
#
# This means that the desired signal can be computed with the weighting
#
#   s V₁  =  s̄ W V₁  ≡  s̄ conj(X) (1/√2D) V₁  ≡  s̄ ᾱ
#
# where  ᾱ ≡ conj(X) * 1/√2D * V₁

sv = svd(s)
ᾱ = W*sv.V[:,1]
ᾱ = (1 ./ sum(abs,ᾱ)) .* ᾱ

combiner = TriMRS.ChannelCombiner(ᾱ, :)

fid = mean(combiner.(sampledata.(Ref(twix), 2:97)))

combiner2 = pca_channel_combiner([sampledata(twix,1)])
fid2 = mean(combiner2.(sampledata.(Ref(twix), 2:97)))

scale_1(x) = x ./ sum(abs.(x))

spec1 = scale_1(fftshift(fft(fid.data)))
spec2 = scale_1(fftshift(fft(fid2.data)))
clf()
plot(abs.(spec1))
plot(abs.(spec2))

# TODO: I seem to get different results using different ways of measuring the
# remaining noise (ie, in spectral vs time domain.  Why would this be?
#
# Perhaps we can use the eja PRESS sequences pure noise signal as another way
# of debugging this?

@show cov(fid[end-200:end])   / cov(fid2[end-200:end])
@show cov(spec1[end-200:end]) / cov(spec2[end-200:end])
;
