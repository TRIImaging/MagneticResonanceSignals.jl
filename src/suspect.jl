# Wrappers for python suspect library

#-------------------------------------------------------------------------------
# IO

"""
    load_twix_suspect(file_name)

Load data from Siemens TWIX .dat format using suspect
"""
function load_twix_suspect(args...)
    # TODO: Can we load the time increment data in t1 direction from here too?
    # Answer... no, suspect doesn't support it!
    pyob = pycall(suspect.io[:load_twix], PyObject, args...)
    data = convert(PyAny, pyob)
    SpectroData(data,
                pyob[:f0],
                [pyob[:dt], 0.0008],  # ASSUMED srcosy default t1 increment!!!
                te=1e-3*pyob[:te],
                metadata=pyob[:metadata])
end



#-------------------------------------------------------------------------------
# Processing

"""
Combine coil channels using SVD based weightings
"""
function combine_channels(channel_data)
    d = transpose(channel_data)
    weights = suspect.processing[:channel_combination][:svd_weighting](d)
    suspect.processing[:channel_combination][:combine_channels](d, weights)
end

"""
    get_fid(fids, t1_index, repetition)

Get the FID for a given `repetition` and `t1_index`, performing channel
combination.
"""
function get_fid(fids::SpectroData, t1_index, repetition)
    combine_channels(fids.data[repetition,t1_index,:,:])
end

