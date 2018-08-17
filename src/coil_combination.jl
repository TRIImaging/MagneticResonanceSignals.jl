#-------------------------------------------------------------------------------
# Combination of signals from multiple coils
#

"""
Functor for weighted combination of signal from multiple coils.  Create using
`pca_channel_combiner()`.

Channels combination weights should have
* The correct phase so that signals constructively interfere
* The correct amplitude to achieve the best signal to noise ratio

These factors depend on the relative geometry of the sample vs coil for each
channel, and may be inferred from one or more acquisitions, depending on the
experiment.
"""
struct ChannelCombiner
    weights::Vector{Complex128}
end

(combiner::ChannelCombiner)(data) = combine_channels(combiner, data)

# Combine channels data residing in a `NxC` matrix `data`, where `N` is number
# of temporal samples and `C` the number of channels.
combine_channels(combiner::ChannelCombiner, data::Matrix) = data * combiner.weights
combine_channels(combiner::ChannelCombiner, acq::Acquisition) = acq.data * combiner.weights


# Deduce channel weights from the data itself
combine_channels(acq::Acquisition) = pca_channel_combiner([acq])(acq)


"""
    pca_channel_combiner(acquisitions::Vector{Acquisition}; signal_range=nothing)

Compute channel combination object using PCA, assuming that each acquisition in
`acquisitions` has the same relative geometry of sample and coils.  We use the
first few samples of all acquisition data together in the same calculation to
get a good estimate of the correct channel weights.

These assumptions should be valid to assess the relative coil SNR for
spectroscopy of a single voxel; for other experiments you may want to use a
different method, or restrict calculation of weights to a different
`signal_range`.
"""
function pca_channel_combiner(acqs::Vector{Acquisition}; signal_range=nothing)
    # Select set of time series data from multiple acquisitions, containing
    # mostly signal rather than noise.
    if signal_range == nothing
        # Crude heuristic: Try to focus on a part of the time series containing
        # mostly signal (ie, the start).
        #
        # Using the start of the signal will fail if it's an echo, so arguably
        # we could do something better here...
        signal_range = 1:min(100, size(acqs[1].data,1))
    end
    signal = vcat([a.data[signal_range,:] for a in acqs]...)

    # Compute PCA via the correlation matrix
    evals,evecs = eig(signal'*signal)
    # Weights arise from the first principle component
    pc1_index = indmax(evals)
    weights = evecs[:,pc1_index]

    # TODO:
    # * What's the most appropriate normalization for the weights?
    # * Is there any sensible phase factor we should add here?
    ChannelCombiner((1./sum(abs.(weights))) .* weights)
end


# Following would be handy, but how do we figure out which acquisitions relate
# to the channel combination we're interested in?
# pca_channel_combiner(expt::MRExperiment; kws...) = pca_channel_combiner(expt.data, kws...)
