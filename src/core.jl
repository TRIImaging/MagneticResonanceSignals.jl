# Core abstractions for the package

struct MRMetadata
    protocol_name
    sequence_name
    software_version
    ref_epoch # Epoch of localizer image
end

"""
Extract standard MR metadata about an experiment
"""
function standard_metadata
end

"""
    mr_recognize(data)

Recognize the experiment type based on raw MR `data`, and return metadata
describing the experimental conditions and acquisition schedule which can be
used during data processing.

The idea here is to separate the processing steps from the recognition of the
raw data.

If the experiment is not recognized, throw an exception.
"""
function mr_recognize
end


