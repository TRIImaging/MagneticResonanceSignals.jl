# Wrappers for python suspect library

using PyCall

@pyimport suspect as suspect

#-------------------------------------------------------------------------------
# IO

"""
    load_twix(file_name)

Load data from Siemens TWIX .dat format, returning it in an FIDData object.
"""
function load_twix(args...)
    # TODO: Can we load the time increment data in t1 direction from here too?
    # Answer... no, suspect doesn't support it!
    pyob = pycall(suspect.io[:load_twix], PyObject, args...)
    data = convert(PyAny, pyob)
    FIDData(data,
            pyob[:f0],
            pyob[:dt],
            pyob[:te],
            metadata=pyob[:metadata])
end



#-------------------------------------------------------------------------------
# Processing

"""
Combine coil channels using SVD based weightings
"""
function combine_channels(channel_data)
    weights = suspect.processing[:channel_combination][:svd_weighting](channel_data)
    suspect.processing[:channel_combination][:combine_channels](channel_data, weights)
end

"""
Get the FID for a given `repetition` and `t1_index`, performing channel
combination.
"""
function get_fid(fids::FIDData, t1_index, repetition)
    combine_channels(fids.data[repetition,t1_index,:,:])
end

