#-------------------------------------------------------------------------------
# Representation of raw acquisition data

"""
Data stored in the header preceding each channel of a raw acquisition
"""
struct ChannelHeader
    meas_uid      ::UInt32
    scan_counter  ::UInt32
    sequence_time ::UInt32
    channel_id    ::UInt16
end

"""
Data from a single acquisition by a Siemens MR scanner (software version VD?)
"""
struct Acquisition
    # Measurement Data Header (MDH) section.
    meas_uid                    ::UInt32
    scan_counter                ::UInt32
    time_stamp                  ::UInt32
    pmu_time_stamp              ::UInt32
    system_type                 ::UInt16
    # ptab?
    ptab_pos_delay              ::UInt16
    ptab_pos_x                  ::UInt32
    ptab_pos_y                  ::UInt32
    ptab_pos_z                  ::UInt32
    # flags (bitpacked in raw MDH data)
    # TODO: Consider leaving these packed & using `getproperty()`?
    acq_end                     ::Bool    # Set on placeholder packet after sequence end.
    rt_feedback                 ::Bool    # Real time feedback (ICE will process acquisition ASAP)
    hp_feedback                 ::Bool    # High priority feedback (?)
    sync_data                   ::Bool    # Data following will be seq->ICE raw data transfer (not an acquisition)
    raw_data_correction         ::Bool
    ref_phase_stab_scan         ::Bool
    phase_stab_scan             ::Bool
    sign_rev                    ::Bool
    phase_correction            ::Bool
    pat_ref_scan                ::Bool
    pat_ref_ima_scan            ::Bool
    reflect                     ::Bool
    noise_adj_scan              ::Bool
    # raw data size from ADC
    num_samples                 ::UInt16
    num_channels                ::UInt16
    loop_counters               ::SVector{14,UInt16}
    cut_off_data                ::UInt32
    kspace_centre_column        ::UInt16
    coil_select                 ::UInt16
    readout_offcentre           ::UInt32
    time_since_rf               ::UInt32
    kspace_centre_line_num      ::UInt16
    kspace_centre_partition_num ::UInt16
    slice_position              ::SVector{7,Float32}
    # per-acquisition sequence-dependent parameters as passed to ICE program.
    ice_program_params          ::SVector{24,UInt16}
    reserved_params             ::SVector{4,UInt16}
    application_counter         ::UInt16
    application_mask            ::UInt16
    # Measured magnetization
    channel_info::Vector{ChannelHeader} # num_channels
    data::Matrix{Complex64}           # num_samples × num_channels
end
end

"""
    MRExperiment(metadata, acq_data)

Container for data from a magnetic resonance experiment: a series of
excitations and acquired free induction decays.
"""
struct MRExperiment
    metadata
    data::Vector{Acquisition}
end

"""
Get labels for loop counters.

TODO: Need to verify how this depends on software version number
"""
counter_labels(::MRExperiment) =
    ["line", "acquisition", "slice", "partition", "echo",
     "phase", "repetition", "set", "seg",
     "ida", "idb", "idc", "idd", "ide"]

"""
Extract the date and time of the localizer images used as reference
"""
function ref_epoch(expt::MRExperiment, search_key=r"^tReferenceImage")
    # On the IDEA forum, Eddie Auerbach suggests:
    #   "tReferenceImage0,1,2 are the unique IDs for the 3 localizer images
    #   used for slice prescription. In YAPS you have tFrameOfReference,
    #   which I'm guessing is an ID for the last acquired shim phasemap."
    dts = []
    for (k,str) in meta_search(expt, search_key)
        try
            push!(dts, DateTime(last(split(str, '.'))[1:14], dateformat"yyyymmddHHMMSS"))
        catch
            # There seems to commonly (always?) be an invalid datetime in the
            # year 3000 here - just ignore that one.
        end
    end
    isempty(dts) ? nothing : minimum(dts)
end

"""
Extract scanner software version from experiment metadata
"""
function software_version(expt::MRExperiment)
    get(expt.metadata, "sProtConsistencyInfo.tBaselineString") do
        get(expt.metadata, "sProtConsistencyInfo.tMeasuredBaselineString",nothing)
    end
end

struct MRMetadata
    protocol_name
    sequence_name
    software_version
    ref_epoch # Epoch of localizer image
end

"""
Get some standard MR metadata
"""
function standard_metadata(expt::MRExperiment)
    protname = get(expt.metadata,"tProtocolName",nothing)
    seqname = get(expt.metadata,"tSequenceFileName",nothing)
    epoch = ref_epoch(expt)
    version = software_version(expt)
    MRMetadata(protname, seqname, version, epoch)
end

"""
    scanner_time(acq | expt)

Get internal scanner time stamp from an acquisition or sequence of timestamps
from an experiment.
"""
scanner_time(expt::MRExperiment) = scanner_time.(expt.data)
# 2.5 ms per count... is this reliable?
scanner_time(acq::Acquisition) = 0.0025 * acq.time_stamp

function Base.show(io::IO, expt::MRExperiment)
    println(io, "MRExperiment metadata:")
    meta = standard_metadata(expt)
    print(io, """
            Protocol           = $(meta.protocol_name)
            Sequence File Name = $(meta.sequence_name)
            Software Version   = $(meta.software_version)
            Reference Date     = $(meta.ref_epoch)
          """)
    if isempty(expt.data)
        return
    end
    tmin,tmax = extrema(scanner_time(expt))
    print(io, rstrip("""
          Acquisition summary:
            Number   = $(length(expt.data))
            Duration = $(round(tmax-tmin,2)) s
          """))
    println(io,
    )
    counters = [a.loop_counters for a in expt.data]
    sep = ""
    for (i,label) in enumerate(counter_labels(expt))
        cntmin,cntmax = extrema(c[i] for c in counters)
        if cntmin != 0 || cntmax != 0
            print(io, sep, "  Loop index $i in [$cntmin,$cntmax]   ($label)")
            sep = "\n"
        end
    end
end

#-------------------------------------------------------------------------------
# Functions for loading Siemens TWIX data

function check_twix_type(io)
    # Detect whether this is a twix file from VB or VD software version,
    # using a magic number heuristic from suspect.py
    m1,m2 = read(io, UInt32, 2)
    seek(io, 0)
    if m1 == 0 && m2 < 64
        return :vd
    else
        error("""
              Unknown TWIX type (TWIX VB?  Or not a TWIX file?).
              You could try siemens_to_ismrmd or suspect.py as alternatives.""")
    end
end

"""
    load_twix(filename; header_only=false, acquisition_filter=(acq)->true)

Load raw Siemens twix ".dat" format, producing an `MRExperiment` containing a
sequence of acqisitions.

For large files, acquisitions may be filtered out during file loading by
providing a predicate `acquisition_filter(acq)` which returns true when `acq`
should be kept.  By default, all acquisitions are retained.
"""
function load_twix(filename; header_only=false, acquisition_filter=(acq)->true,
                   meas_selector=(inds)->last(inds))
    # TWIX is little endian binary data, with ascii header
    open(filename) do io
        check_twix_type(io)
        header_sections,acquisitions = load_twix_vd(io, header_only, acquisition_filter,
                                                    meas_selector)
        # For now parse the MeasYaps section as it's is the easiest to parse and
        # contains parameters relevant to downstream interpretation by the ICE
        # program (...I think?)
        metadata = parse_header_yaps(header_sections["MeasYaps"])
        MRExperiment(metadata, acquisitions)
    end
end

"""
    dump_twix_headers(filename, dump_dir)

Dump twix header sections verbatim into files `dump_dir/sect_name`, one for
each section.  Mostly useful for debugging.
"""
function dump_twix_headers(filename, dump_dir)
    if !isdir(dump_dir)
        mkdir(dump_dir)
    end
    # TWIX is little endian binary data, with ascii header
    open(filename) do io
        check_twix_type(io)
        header_sections,acquisitions = load_twix_vd(io, true, (a)->true, (inds)->last(inds))
        for (sect_name,sect_data) in header_sections
            open(joinpath(dump_dir, sect_name), "w") do out
                write(out, sect_data)
            end
        end
    end
end

function read_zero_packed_string(io, length)
    data = read(io, length)
    firstnull = findfirst(data, 0)
    strend = firstnull > 0 ? firstnull-1 : firstnull = length(data)
    String(data[1:strend])
end


# The following is inspired by the twix reader in suspect.py.
function load_twix_vd(io, header_only, acquisition_filter, meas_selector)
    twix_id, num_measurements = read(io, Int32, 2)
    # vd file can contain multiple measurements, but we only want the MRS.
    # Assume that the MRS is the last measurement.
    measurement_index = meas_selector(1:num_measurements)

    # measurement headers are each 152 bytes at start of segment
    seek(io, 8 + 152 * (measurement_index-1))
    meas_uid, file_id = read(io, Int32, 2)
    meas_offset, meas_length = read(io, Int64, 2)
    patient_name = read_zero_packed_string(io, 64)
    protocol_name = read_zero_packed_string(io, 64)
    @debug "Reading TWIX VD Header" meas_uid file_id patient_name protocol_name

    # offset points to where the actual data is in the file
    seek(io, meas_offset)

    header_size = read(io, UInt32)
    header      = read(io, header_size - sizeof(UInt32))
    header_sections = parse_twix_header_sections(IOBuffer(header))

    acquisitions = Acquisition[]
    if header_only
        return header_sections, acquisitions
    end

    # read each scan until we hit the acq_end flag
    while true
        # the first four bytes contain some composite information
        temp = read(io, UInt32)
        DMA_length = temp & (2^26 - 1)
        pack_flag = Bool((temp >> 25) & 1)
        PCI_rx = temp >> 26
        #@show DMA_length pack_flag PCI_rx

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

        # Real time data comes in several flavours:
        #   * MR data (coil potentials) as recorded by the ADC
        #   * Physiological data as recorded by the PMU (physiological measurement unit)
        #   * Real time sync data from sequence program to ICE
        #
        # For now, we ignore non-MR data which has a different binary layout.
        if sync_data || hp_feedback
            @info "Ignoring unknown data packet" sync_data hp_feedback
            continue
        end
        #=
        if rt_feedback || hp_feedback || phase_correction || noise_adj_scan || sync_data
            continue
        end
        =#

        num_samples, num_channels = read(iob, SVector{2,UInt16})
        # TODO: Ordering of loop counters have changed between software versions!!
        # 
        # read_meas_dat_mdh_binary__alt.m Lists the ordering of the loop counters as
        # line,acquisition,slice,partition,echo,phase,repetition,set,seg,ida,idb,idc,idd,ide.
        #
        # It looks like this was right as of software version D11, but changed
        # in a later version (at least set & repetition were swapped) (FIXME!)
        loop_counters = read(iob, SVector{14,UInt16})

        #@show Int(num_samples) Int(num_channels)
        #@show Int.(loop_counters)

        cut_off_data                = read(iob, UInt32)
        kspace_centre_column        = read(iob, UInt16)
        coil_select                 = read(iob, UInt16)
        readout_offcentre           = read(iob, UInt32)
        time_since_rf               = read(iob, UInt32)
        kspace_centre_line_num      = read(iob, UInt16)
        kspace_centre_partition_num = read(iob, UInt16)
        slice_position              = read(iob, SVector{7,Float32})
        ice_program_params          = read(iob, SVector{24,UInt16})
        reserved_params             = read(iob, SVector{4,UInt16})
        application_counter         = read(iob, UInt16)
        application_mask            = read(iob, UInt16)
        crc                         = read(iob, UInt32)

        #fid_start_offset = Int(ice_program_params[5])
        #num_dummy_points = Int(reserved_params[1])
        #fid_start = fid_start_offset + num_dummy_points
        # Suspect slices the raw data as follows. Why!?  (Is this specific to
        # Siemens SVS program?)
        #np = 2^floor(Int, log2(num_samples - fid_start))

        # read the data for each channel in turn
        channel_info = ChannelHeader[]
        data = zeros(Complex64, (num_samples, num_channels))
        for channel_index = 1:num_channels
            dma_length    = read(iob, UInt32)
            meas_uid      = read(iob, UInt32)
            scan_counter  = read(iob, UInt32)
                            read(iob, UInt32) # skip (padding? observed to be zeroed)
            sequence_time = read(iob, UInt32)
                            read(iob, UInt32) # skip
            channel_id    = read(iob, UInt16)
                            read(iob, UInt16) # skip
                            read(iob, UInt32) # skip
            push!(channel_info, ChannelHeader(meas_uid, scan_counter, sequence_time, channel_id))
            raw_data = read(iob, Complex64, num_samples)
            # NB: The quadrature convetion used in twix is the opposite of what
            # we'd like for spectro: We want the positive frequencies after a
            # simple fft to correspond to a positive offset from the
            # spectrometer reference frequency. But in twix they are negative
            # so directly doing an fft of the raw data would flip the frequency
            # axis.  We add a conj to standardize the convention.
            #
            # TODO: Perhaps should reconsider this, to preserve the original
            # data as much as possible? Consider starting to version TriMRS if
            # this is to be changed. Need a better interface to the raw data so
            # we have flexibility in storing the underlying data.
            data[:,channel_index] .= conj.(raw_data)
        end
        acq = Acquisition(
            meas_uid, scan_counter, time_stamp, pmu_time_stamp,
            system_type, ptab_pos_delay, ptab_pos_x, ptab_pos_y, ptab_pos_z,
            acq_end, rt_feedback, hp_feedback, sync_data, raw_data_correction,
            ref_phase_stab_scan, phase_stab_scan, sign_rev, phase_correction,
            pat_ref_scan, pat_ref_ima_scan, reflect, noise_adj_scan,
            num_samples, num_channels, loop_counters,
            cut_off_data, kspace_centre_column, coil_select, readout_offcentre,
            time_since_rf, kspace_centre_line_num, kspace_centre_partition_num, slice_position,
            ice_program_params, reserved_params, application_counter, application_mask,
            channel_info, data)
        if acquisition_filter(acq)
            push!(acquisitions, acq)
        end
    end
    header_sections, acquisitions
end


function parse_twix_header_sections(io)
    # The VD twix header is a list of header sections containing ascii data but
    # connected with binary section sizes.
    #
    # Here's some (typical?) section names:
    # Config, Dicom, Meas, MeasYaps, Phoenix, Spice
    num_sec = read(io, UInt32)
    sections = Dict{String,String}()
    for sec_index = 1:num_sec
        sec_name    = String(readuntil(io, '\0')[1:end-1])
        sec_size    = read(io, UInt32)
        sec_content = read(io, sec_size)
        if sec_content[end] == 0
            sec_content = sec_content[1:end-1]
        end
        sections[sec_name] = String(sec_content)
    end
    sections
end

function parse_header_yaps(yaps)
    metadata = Dict{String,Any}()
    for line in split(yaps, '\n')
        if startswith(line, "### ASCCONV BEGIN") || startswith(line, "### ASCCONV END") || isempty(line)
            continue
        end
        m = match(r"^([^#\s]+)\s*=\s*(.*?)\s*$", line)
        if m != nothing
            # Cheat a bit by using the julia parser for the RHS
            metadata[m[1]] = parse(m[2])
        else
            @warn "could not match YAPS header line \"$(Vector{UInt8}(line))\""
        end
    end
    metadata
end

"""
    meta_search(metadata, pattern)

Search through MR experiment `metadata` for a given regular expression,
`pattern` or for a case insensitive string `pattern`.
"""
function meta_search(expt::MRExperiment, pattern)
    Dict(k=>v for (k,v) in expt.metadata if ismatch(pattern, k))
end
function meta_search(expt::MRExperiment, pattern::String)
    Dict(k=>v for (k,v) in expt.metadata if ismatch(Regex(pattern,"i"), k))
end
