
"""
Zero pad an FID for a bit of Fourier interpolation
"""
function zero_pad(fid, pad::Integer)
    [fid;
     zeros((pad-1)*length(fid))]
end

#=
function combine_fids(fids)
    fids = similar(fids, (size(fids,2), size(fids,4)))
    for i = 1:size(fids,2)
        fids[i,:] = get_fid(fids, i)
    end
    fids
end
=#

