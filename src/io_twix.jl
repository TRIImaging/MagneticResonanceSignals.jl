function load_twix2(filename)
    # TWIX is little endian binary data, with ascii header
    open(filename) do io
        # Detect wether this is a twix file from VB or VD software version,
        # using a magic number heuristic from suspect.py
        m1,m2 = read(io, UInt32, 2)
        seek(io, 0)
        if m1 == 0 && m2 < 64
            load_twix_vd(io)
        else
            error("TWIX VB not supported - use suspect.py instead")
        end
    end
end

function read_zero_packed_string(io, length)
    data = read(io, length)
    firstnull = findfirst(data, 0)
    strend = firstnull > 0 ? firstnull-1 : firstnull = length(data)
    String(data[1:strend])
end

# The following is mostly a direct port of the twix reader in suspect.py.
function load_twix_vd(io)
    twix_id, num_measurements = read(io, Int32, 2)
    # vd file can contain multiple measurements, but we only want the MRS.
    # Assume that the MRS is the last measurement.
    measurement_index = num_measurements - 1

    # measurement headers are each 152 bytes at start of segment
    seek(io, 8 + 152 * measurement_index)
    meas_id, file_id = read(io, Int32, 2)
    offset, length = read(io, Int64, 2)
    patient_name = read_zero_packed_string(io, 64)
    protocol_name = read_zero_packed_string(io, 64)

    # offset points to where the actual data is in the file
    seek(io, offset)

    header_size = read(io, UInt32)
    # suspect.py uses a latin-1 conversion, but some of the header is binary.
    # OTOH, wrapping with a `String` here assumes utf-8, which is probably
    # equally incorrect...  Both work for some simple regex matching of the
    # ascii parts however.
    header = String(read(io, header_size - sizeof(UInt32)))

    scans = Any[]
    # read each scan until we hit the acq_end flag
    while true
        # the first four bytes contain some composite information
        temp = read(io, UInt32)
        DMA_length = temp & (2^26 - 1)
        pack_flag = Bool((temp >> 25) & 1)
        PCI_rx = temp >> 26

        iob = IOBuffer(read(io, DMA_length-sizeof(UInt32)))
        meas_uid, scan_counter, time_stamp, pmu_time_stamp = read(iob, UInt32, 4)
        system_type, ptab_pos_delay = read(iob, UInt16, 2)
        ptab_pos_x, ptab_pos_y, ptab_pos_z, reserved = read(iob, UInt32, 4)

        # more composite information
        eval_info_mask      = read(iob, UInt64)
        acq_end             = Bool((eval_info_mask      ) & 1)
        rt_feedback         = Bool((eval_info_mask >> 1 ) & 1)
        hp_feedback         = Bool((eval_info_mask >> 2 ) & 1)
        sync_data           = Bool((eval_info_mask >> 5 ) & 1)
        raw_data_correction = Bool((eval_info_mask >> 10) & 1)
        ref_phase_stab_scan = Bool((eval_info_mask >> 14) & 1)
        phase_stab_scan     = Bool((eval_info_mask >> 15) & 1)
        sign_rev            = Bool((eval_info_mask >> 17) & 1)
        phase_correction    = Bool((eval_info_mask >> 21) & 1)
        pat_ref_scan        = Bool((eval_info_mask >> 22) & 1)
        pat_ref_ima_scan    = Bool((eval_info_mask >> 23) & 1)
        reflect             = Bool((eval_info_mask >> 24) & 1)
        noise_adj_scan      = Bool((eval_info_mask >> 25) & 1)
        # if acq_end is set, there is no more data
        if acq_end
            break
        end

        # there are some data frames that contain auxilliary data, we ignore those for now
        if rt_feedback || hp_feedback || phase_correction || noise_adj_scan || sync_data
            continue
        end

        num_samples, num_channels = read(iob, UInt16, 2)
        loop_counters = read(iob, UInt16, 14)

        #@show Int(num_samples) Int(num_channels)
        #@show Int.(loop_counters)

        cut_off_data                = read(iob, UInt32)
        kspace_centre_column        = read(iob, UInt16)
        coil_select                 = read(iob, UInt16)
        readout_offcentre           = read(iob, UInt32)
        time_since_rf               = read(iob, UInt32)
        kspace_centre_line_num      = read(iob, UInt16)
        kspace_centre_partition_num = read(iob, UInt16)
        slice_position              = read(iob, Float32, 7)
        ice_program_params          = read(iob, UInt16, 24)
        reserved_params             = read(iob, UInt16, 4)
        application_counter         = read(iob, UInt16)
        application_mask            = read(iob, UInt16)
        crc = read(iob, UInt32)

        fid_start_offset = ice_program_params[5]
        num_dummy_points = reserved_params[1]
        fid_start = fid_start_offset + num_dummy_points
        np = 2^floor(Int, log2(num_samples - fid_start))

        # read the data for each channel in turn
        scan_data = zeros(Complex64, (num_channels, np))
        for channel_index = 1:num_channels
            # start with the header
            dma_length    = read(iob, UInt32)
            meas_uid      = read(iob, UInt32)
            scan_counter  = read(iob, UInt32)
                            read(iob, UInt32) # skip
            sequence_time = read(iob, UInt32)
                            read(iob, UInt32) # skip
            channel_id    = read(iob, UInt16)
                            read(iob, UInt16) # skip
                            read(iob, UInt32) # skip
            #@show sequence_time
            #@show channel_id

            # Now the data itself
            raw_data = read(iob, Complex64, num_samples)
            # For some reason, suspect conjugates the raw sample data (perhaps
            # to satisfy its quadrature detection convention?)
            scan_data[channel_index,:] .= conj.(raw_data[fid_start+1:fid_start+np])
        end
        push!(scans, (loop_counters, scan_data))
    end
    scans
end


function parse_twix_header(header)
    # The twix "header" is a big mix of ASCII and binary data.  The ASCII data
    # is a mixture of psuedo-json like structured configuration data, and more
    # INI-like output in the "MeasYaps ASCCONV" section
end

