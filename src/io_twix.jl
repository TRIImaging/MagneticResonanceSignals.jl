#-------------------------------------------------------------------------------
# Representation of raw acquisition data

using Dates

"""
Data stored in the header preceding each channel of a raw acquisition
"""
struct ChannelHeader
    meas_uid      ::UInt32
    scan_counter  ::UInt32
    sequence_time ::UInt32
    channel_id    ::UInt16
end

struct LoopCounters <: FieldVector{14, UInt16}
    line::UInt16
    acquisition::UInt16
    slice::UInt16
    partition::UInt16
    echo::UInt16
    phase::UInt16
    repetition::UInt16
    set::UInt16
    seg::UInt16
    ida::UInt16
    idb::UInt16
    idc::UInt16
    idd::UInt16
    ide::UInt16
end

loop_counter_index(name) = findfirst(isequal(name), fieldnames(TriMRS.LoopCounters))::Int


"""
Data from a single acquisition by a Siemens MR scanner (software version VD?)
"""
struct Acquisition
    # Measurement Data Header (MDH) section.
    meas_uid                    ::UInt32
    scan_counter                ::UInt32
    time_stamp                  ::UInt32  # Mars time stamp?
    pmu_time_stamp              ::UInt32  # phase measurement unit time stamp (on Rx??)
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
    # Hypercube indexing system for comms with reconstruction code
    loop_counters               ::LoopCounters
    # Info about precise timing of digital samples
    cutoff_pre                  ::UInt16
    cutoff_post                 ::UInt16
    kspace_centre_column        ::UInt16
    coil_select                 ::UInt16
    readout_offcentre           ::Float32
    time_since_rf               ::UInt32
    kspace_centre_line_num      ::UInt16
    kspace_centre_partition_num ::UInt16
    # 3D coordinage system
    slice_position              ::SVector{3,Float32} # offset (saggital,coronal,transverse) ?
    slice_rotation_quat         ::SVector{4,Float32}
    # per-acquisition sequence-dependent parameters as passed to ICE program.
    ice_program_params          ::SVector{24,UInt16}
    reserved_params             ::SVector{4,UInt16}
    application_counter         ::UInt16
    application_mask            ::UInt16
    # Measured magnetization
    channel_info::Vector{ChannelHeader} # num_channels
    data::Matrix{ComplexF32}           # num_samples × num_channels
end


#-------------------------------------------------------------------------------
# Metadata

"""
Data quality control flags for raw file parsing.

We generally use these flags rather than returning hard errors because it's
useful to be able to parse apparently incomplete or partially corrupt raw data.

Flags include:

* AcquisitionsIncomplete - the acquisition list appeared to be truncated
"""
@enum DataStatus AcquisitionsIncomplete MeasHeaderEmpty

"""
    RxCoilElementData(
        element, coil_id, unique_key, coil_copy, coil_type,
        rx_channel_connected, adc_channel_connected, mux_channel_connected,
        insertion_time, element_selected
    )

Siemens MR receiver coil element data.

## Logical connectivity
adc_channel_connected corresponds to the `channel_id` in the channel
acquisition header, though off by 1 (?!)

## Physical connectivity:
`rx_channel_connected` is duplicated in Siemens "dual-density" systems - two
coils are transmitted on a single wire with different carrier frequencies.
These are (presumably) split before ADC, and ADC channels come in pairs.
"""
struct RxCoilElementData
    # CoilElementID
    element::String
    coil_id::String
    unique_key::UInt32
    coil_copy::Int
    # CoilProperties
    coil_type::Int
    # Physical / logical connectivity
    rx_channel_connected::Int
    adc_channel_connected::Int
    mux_channel_connected::Int
    insertion_time::Int
    element_selected::Int
end


#-------------------------------------------------------------------------------
"""
    load_twix(twix_file_name)
    load_twix(io)

    MRExperiment(metadata, coils, quality_control, acq_data)

Container for data from a generic magnetic resonance experiment: a series of
`Acquisition`s, each of which records the coil response due to induced nuclear
magnetization.

Note that the input pulse sequence is not recorded in Siemens raw format, so
it's not available here. The only way to know this in full detail is to
simulate the sequence with the same input parameters using the Siemens `poet`
tool from the Siemens proprietary IDEA development environment.
"""
struct MRExperiment
    metadata # TODO: rename to yaps, as we're only parsing yaps data.
    coils::Vector{RxCoilElementData}
    quality_control::Set{DataStatus}
    data::Vector{Acquisition}
end

"""
Get labels for loop counters (valid for VE11C)
"""
counter_labels(::MRExperiment) =
    ["line", "acquisition", "slice", "partition", "echo",
     "phase", "repetition", "set", "seg",
     "ida", "idb", "idc", "idd", "ide"]

"""
Extract the date and time of the localizer images used as reference
"""
function ref_epoch(expt::MRExperiment)
    # On the IDEA forum, Eddie Auerbach suggests:
    #   "tReferenceImage0,1,2 are the unique IDs for the 3 localizer images
    #   used for slice prescription. In YAPS you have tFrameOfReference,
    #   which I'm guessing is an ID for the last acquired shim phasemap."
    dts = []
    for (k,str) in meta_search(expt, "tReferenceImage")
        try
            push!(dts, DateTime(last(split(str, '.'))[1:14], dateformat"yyyymmddHHMMSS"))
        catch
            # There seems to commonly (always?) be an invalid datetime in the
            # year 3000 here - just ignore that one.
        end
    end
    if !isempty(dts)
        return minimum(dts)
    end
    # Some scans may not have tReferenceImage however it seems there can be a
    # tFrameOfReference in the Yaps section of the Meas header. (For whatever
    # reason this doesn't make it into the MeasYaps header??)
    try
        m = match(r"\.(2\d{13})", expt.metadata["Meas.tFrameOfReference"])
        return DateTime(m[1], dateformat"yyyymmddHHMMSS")
    catch exc
        @warn "Could not find date of scan (reference epoch) in twix metadata" exception=exc
        return missing
    end
end

function ref_epoch(expt::MRExperiment, search_key)
    dts = []
    for (k,str) in meta_search(expt, search_key)
        try
            push!(dts, DateTime(last(split(str, '.'))[1:14], dateformat"yyyymmddHHMMSS"))
        catch
            # There seems to commonly (always?) be an invalid datetime in the
            # year 3000 here - just ignore that one.
        end
    end
    isempty(dts) ? missing : minimum(dts)
end

"""
Extract scanner software version from experiment metadata
"""
function software_version(expt::MRExperiment)
    get(expt.metadata, "sProtConsistencyInfo.tBaselineString") do
        get(expt.metadata, "sProtConsistencyInfo.tMeasuredBaselineString", missing)
    end
end

function standard_metadata(expt::MRExperiment)
    protname = get(expt.metadata, "tProtocolName", missing)
    seqname = get(expt.metadata, "tSequenceFileName", missing)
    frequency = get(expt.metadata, "sTXSPEC.asNucleusInfo[0].lFrequency",missing)*u"Hz"
    epoch = ref_epoch(expt)
    version = software_version(expt)
    MRMetadata(protname, seqname, version, epoch, frequency)
end

"""
    scanner_time(acq | expt)

Get internal scanner time stamp from an acquisition or sequence of timestamps
from an experiment.
"""
scanner_time(expt::MRExperiment) = scanner_time.(expt.data)
# 2.5 ms per count... is this reliable?
scanner_time(acq::Acquisition) = 0.0025u"s" * acq.time_stamp

dwell_time(expt::MRExperiment) = expt.metadata["sRXSPEC.alDwellTime[0]"]*u"ns"

function Base.show(io::IO, expt::MRExperiment)
    println(io,
         "MRExperiment metadata:")
    meta = standard_metadata(expt)
    print(io, """
            Protocol           = $(meta.protocol_name)
            Sequence File Name = $(meta.sequence_name)
            Software Version   = $(meta.software_version)
            Reference Date     = $(meta.ref_epoch)
            Frequency          = $(meta.frequency)
            Coils              = $(unique([c.coil_id for c in expt.coils]))
          """)
    if isempty(expt.data)
        return
    end
    tmin,tmax = extrema(scanner_time(expt))
    print(io, """
          Acquisition summary:
            Number   = $(length(expt.data))
            Duration = $(uconvert(u"s", 1.0*(tmax-tmin)))
          """)
    counters = [a.loop_counters for a in expt.data]
    for (i,label) in enumerate(counter_labels(expt))
        cntmin,cntmax = extrema(c[i] for c in counters)
        if cntmin != 0 || cntmax != 0
            println(io, "  Loop index $i in [$cntmin,$cntmax]   ($label)")
        end
    end
end

#-------------------------------------------------------------------------------
# Functions for loading Siemens TWIX data

function check_twix_type(io)
    # Detect whether this is a twix file from VB or VD software version,
    # using a magic number heuristic from suspect.py
    m1,m2 = read(io, SVector{2,UInt32})
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
    load_twix(filename; header_only=false, acquisition_filter=(acq)->true,
              meas_selector=last)

Load raw Siemens twix ".dat" format, producing an `MRExperiment` containing a
sequence of acqisitions.

For large files, acquisitions may be filtered out during file loading by
providing a predicate `acquisition_filter(acq)` which returns true when `acq`
should be kept.  By default, all acquisitions are retained.

N4 VD-version twix may have data from more than one sequence (for example, the
tune-up data may be included). Normally the data you're looking for is in the
`meas_selector=last` chunk, but meas_selector is provided for the cases where
you want to select other measurements.
"""
function load_twix(io::IO; header_only=false, acquisition_filter=(acq)->true,
                   meas_selector=last)
    # TWIX is little endian binary data, with ascii header
    check_twix_type(io)
    header_sections,quality_control,acquisitions =
        load_twix_vd(io, header_only, acquisition_filter, meas_selector)
    # For now parse the MeasYaps section as it's is the easiest to parse and
    # contains parameters relevant to downstream interpretation by the ICE
    # program (...I think?)
    @debug "Header section names" keys(header_sections)
    metadata = Dict{String,Any}()
    try
        yaps_meta = parse_header_yaps(header_sections["MeasYaps"])
        dicom_meta = match_xprot_header(header_sections["Dicom"], "Dicom.",
                                        ["SoftwareVersions", "DeviceSerialNumber", "InstitutionName", "Manufacturer", "ManufacturersModelName"])
        meas_meta  = match_xprot_header(header_sections["Meas"], "Meas.",
                                        ["tReferenceImage0", "tReferenceImage1", "tReferenceImage2",
                                         "tFrameOfReference"])
        metadata = merge(metadata, yaps_meta, dicom_meta, meas_meta)
    catch exc
        @error "Could not parse header metadata" exception=(exc,catch_backtrace())
    end
    coils = RxCoilElementData[]
    try
        coils = parse_yaps_rx_coil_selection(metadata)
    catch exc
        @error "Could not parse coil metadata" exception=(exc,catch_backtrace())
    end
    MRExperiment(metadata, coils, quality_control, acquisitions)
end

load_twix(filename::String; kws...) = open(io->load_twix(io; kws...), filename)

"""
    dump_twix_headers(filename, dump_dir; meas_selector=last)

Dump twix header sections verbatim into files `dump_dir/sect_name`, one for
each section.  Mostly useful for debugging.
"""
function dump_twix_headers(filename, dump_dir; meas_selector=last)
    if !isdir(dump_dir)
        mkdir(dump_dir)
    end
    # TWIX is little endian binary data, with ascii header
    open(filename) do io
        check_twix_type(io)
        header_sections,_,_ = load_twix_vd(io, true, (a)->true, meas_selector)
        for (sect_name,sect_data) in header_sections
            open(joinpath(dump_dir, sect_name), "w") do out
                write(out, sect_data)
            end
        end
    end
end

function read_zero_packed_string(io, N)
    data = read(io, N)
    firstnull = findfirst(data .== 0)
    strend = firstnull==nothing ? length(data) : firstnull-1
    String(data[1:strend])
end


# The following is inspired by the twix reader in suspect.py.
function load_twix_vd(io, header_only, acquisition_filter, meas_selector)
    twix_id, num_measurements = read(io, SVector{2,Int32})
    # vd file can contain multiple measurements, but we only want the MRS.
    # Assume that the MRS is the last measurement.
    @debug "Opened TWIX VD" twix_id num_measurements

    measurement_data = []
    for i=1:num_measurements
        meas_uid, file_id = read(io, SVector{2,Int32})
        meas_offset, meas_length = read(io, SVector{2,Int64})
        patient_name = read_zero_packed_string(io, 64)
        protocol_name = read_zero_packed_string(io, 64)
        @debug "Reading TWIX VD Header"   #=
            =# meas_uid file_id           #=
            =# meas_offset meas_length    #=
            =# patient_name protocol_name
        push!(measurement_data,
              (meas_uid=meas_uid, file_id=file_id,
               meas_offset=meas_offset, meas_length=meas_length,
               patient_name=patient_name, protocol_name=protocol_name))
    end
    meas_header = meas_selector(measurement_data)

    seek(io, meas_header.meas_offset)

    acquisitions = Acquisition[]
    quality_control = Set{DataStatus}()

    header_size = read(io, UInt32)
    if header_size < sizeof(UInt32)
        push!(quality_control, MeasHeaderEmpty)
        meas_remaining_bytes = read(io, meas_header.meas_length - sizeof(header_size))
        @warn """
              Unexpected empty measurement header sections; measurement is
              probably corrupt.
              """ header_size length(meas_remaining_bytes) iszero(meas_remaining_bytes)
        return Dict{String,String}(), quality_control, acquisitions
    end
    header      = read(io, header_size - sizeof(UInt32))
    header_sections = parse_twix_header_sections(IOBuffer(header))

    if header_only
        return header_sections, quality_control, acquisitions
    end

    # read each scan until we hit the acq_end flag
    while !eof(io)
        # the first four bytes contain some composite information
        temp = read(io, UInt32)
        DMA_length = temp & (2^26 - 1)
        pack_flag = Bool((temp >> 25) & 1)
        PCI_rx = temp >> 26
        #@show DMA_length pack_flag PCI_rx
        if DMA_length < sizeof(UInt32)
            # From observing various partially complete twix files, this seems
            # to happen when the scan is cancelled.
            @warn "Unexpected empty meas packet before acq_end flag - assuming truncated acquisition" DMA_length
            push!(quality_control, AcquisitionsIncomplete)
            break
        end

        acq_len = DMA_length-sizeof(UInt32)
        acq_buf = read(io, acq_len)
        if length(acq_buf) < acq_len
            @warn "Twix acquisition truncated at position $(position(io))" io
            push!(quality_control, AcquisitionsIncomplete)
            break
        end
        iob = IOBuffer(acq_buf)

        meas_uid       = read(iob, UInt32)
        scan_counter   = read(iob, UInt32)
        time_stamp     = read(iob, UInt32)
        pmu_time_stamp = read(iob, UInt32)

        # NB: Following block is not in VB format data
        system_type    = read(iob, UInt16)
        ptab_pos_delay = read(iob, UInt16)
        ptab_pos_x     = read(iob, UInt32)
        ptab_pos_y     = read(iob, UInt32)
        ptab_pos_z     = read(iob, UInt32)
        reserved       = read(iob, UInt32)

        # more composite information
        eval_info_mask = read(iob, UInt64)

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
            @debug "Ignoring unknown data packet" sync_data hp_feedback maxlog=10
            continue
        end
        #=
        if rt_feedback || hp_feedback || phase_correction || noise_adj_scan || sync_data
            continue
        end
        =#

        num_samples   = read(iob, UInt16)
        num_channels  = read(iob, UInt16)
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

        cutoff_pre                  = read(iob, UInt16)
        cutoff_post                 = read(iob, UInt16)
        kspace_centre_column        = read(iob, UInt16)
        coil_select                 = read(iob, UInt16)   # Dummy in VB ?
        readout_offcentre           = read(iob, Float32)
        time_since_rf               = read(iob, UInt32)
        kspace_centre_line_num      = read(iob, UInt16)
        kspace_centre_partition_num = read(iob, UInt16)
        # TWIX VB Would have following here instead of below; note different length too.
        # ice_program_params          = read(iob, SVector{4,UInt16})
        # reserved_params             = read(iob, SVector{4,UInt16})
        slice_position              = read(iob, SVector{3,Float32})
        slice_rotation_quat         = read(iob, SVector{4,Float32})
        ice_program_params          = read(iob, SVector{24,UInt16})
        reserved_params             = read(iob, SVector{4,UInt16})
        # TWIX VB doesn't have these. Instead
        # channel_id::UInt16
        # ptab_pos_neg::UInt16
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
        data = zeros(ComplexF32, (num_samples, num_channels))
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
            raw_data = read!(iob, Vector{ComplexF32}(undef,num_samples))
            # NB: The quadrature convetion used in twix is such that the
            # positive frequencies after a simple fft to correspond to a
            # *negative* offset from the spectrometer reference frequency.
            data[:,channel_index] .= raw_data
        end
        acq = Acquisition(
            meas_uid, scan_counter, time_stamp, pmu_time_stamp,
            system_type, ptab_pos_delay, ptab_pos_x, ptab_pos_y, ptab_pos_z,
            acq_end, rt_feedback, hp_feedback, sync_data, raw_data_correction,
            ref_phase_stab_scan, phase_stab_scan, sign_rev, phase_correction,
            pat_ref_scan, pat_ref_ima_scan, reflect, noise_adj_scan,
            num_samples, num_channels, loop_counters,
            cutoff_pre, cutoff_post, kspace_centre_column, coil_select, readout_offcentre,
            time_since_rf, kspace_centre_line_num, kspace_centre_partition_num, slice_position,
            slice_rotation_quat, ice_program_params, reserved_params, application_counter,
            application_mask, channel_info, data)
        if acquisition_filter(acq)
            push!(acquisitions, acq)
        end
    end
    header_sections, quality_control, acquisitions
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
        sec_name    = String(readuntil(io, '\0', keep=false))
        sec_size    = read(io, UInt32)
        sec_content = read(io, sec_size)
        if sec_content[end] == 0
            sec_content = sec_content[1:end-1]
        end
        sections[sec_name] = String(sec_content)
    end
    sections
end

function match_xprot_header(xprot_text, key_prefix, xprot_keys)
    # Very heuristic "parsing" of XProtocol header section.
    # Ideally we'd have a proper XProtocol parser (see xprotocol.jl), but that
    # seems like a lot of work.
    metadata = Dict{String,String}()
    for key in xprot_keys
        m = match(Regex("""<ParamString\\."$key">\\s*\\{\\s*"([^}]*)"\\s*\\}""", "s"), xprot_text)
        if m !== nothing
            metadata[key_prefix*key] = m[1]
        end
    end
    metadata
end

function parse_header_yaps(yaps)
    metadata = Dict{String,Any}()
    for line in split(yaps, '\n')
        if startswith(line, "### ASCCONV BEGIN") || startswith(line, "### ASCCONV END") || isempty(line)
            continue
        end
        m = match(r"^([^#\s]+)\s*=\s*(.*?)\s*$", line)
        if m !== nothing
            if occursin(r"^\".*\"$", m[2])
                metadata[m[1]] = m[2][2:end-1]
            elseif occursin(r"^[+-]?\d+\.\d*([eE][-+]?\d+)?$", m[2])
                metadata[m[1]] = parse(Float64, m[2])
            else # assume integer (though may be a float)
                metadata[m[1]] = parse(Int, m[2])
            end
        else
            @warn "could not match YAPS header line \"$(Vector{UInt8}(line))\""
        end
    end
    metadata
end

function parse_yaps_rx_coil_selection(yaps)
    nucleus_index = 0
    prefix = "sCoilSelectMeas.aRxCoilSelectData[$nucleus_index]"
    nuc_name = yaps[prefix*".tNucleus"]
    if nuc_name != "1H"
        @warn "Expected nucleus 0 to be 1H - you will get coil data for $nuc_name instead"
    end
    ncoil = get(yaps, prefix*".asList.__attribute__.size", 0)
    if ncoil == 0
        @warn "No receive coils found in yaps data" yaps
        return
    end
    coils = RxCoilElementData[]
    for i = 0:ncoil-1
        try
            push!(coils, RxCoilElementData(
                yaps[prefix*".asList[$i].sCoilElementID.tElement"],
                yaps[prefix*".asList[$i].sCoilElementID.tCoilID"],
                reinterpret(UInt32, Int32(yaps[prefix*".asList[$i].sCoilElementID.ulUniqueKey"])),
                yaps[prefix*".asList[$i].sCoilElementID.lCoilCopy"],
                yaps[prefix*".asList[$i].sCoilProperties.eCoilType"],
                yaps[prefix*".asList[$i].lRxChannelConnected"],
                yaps[prefix*".asList[$i].lADCChannelConnected"],
                get(yaps, prefix*".asList[$i].lMuxChannelConnected", -1),
                get(yaps, prefix*".asList[$i].uiInsertionTime", -1),
                yaps[prefix*".asList[$i].lElementSelected"],
           ))
        catch exc
            exc isa KeyError || rethrow()
            # Unclear why this happens, but it seems that `ncoil` is not an
            # accurate estimation of the number of coils (is it an upper bound!?)
            # May be common, in which case we should downgrade this to a debug message.
            @warn "Could not find some metadata for coil $i" #=
                =# exc.key
        end
    end
    coils
end

"""
    meta_search(metadata, pattern)

Search through MR experiment `metadata` for a given regular expression,
`pattern` or for a case insensitive string `pattern`.
"""
function meta_search(expt::MRExperiment, pattern)
    Dict(k=>v for (k,v) in expt.metadata if occursin(pattern, k))
end
function meta_search(expt::MRExperiment, pattern::String)
    Dict(k=>v for (k,v) in expt.metadata if occursin(Regex(pattern,"i"), k))
end


#-------------------------------------------------------------------------------
# Raw data extraction and light processing specific to Siemens twix format.
#
# Ideally the functions here don't do signal processing, but defer that to the
# generic signal processing code instead.
#

function sampledata(expt, index; downsample=1)
    acq = expt.data[index]
    # The siemens sequence SVS_SE provides a few additional samples before and
    # after the desired ones. They comment that this is mainly to allow some
    # samples to be cut off after downsampling, (presumably to remove some of
    # the ringing artifacts of doing this with a simple FFT).
    cutpre  = acq.cutoff_pre
    cutpost = acq.cutoff_post
    data = acq.data
    # Adjust time so that the t=0 occurs in the first retained sample
    t = ((0:size(data,1)-1) .- cutpre)*dwell_time(expt)
    t,z = downsample_and_truncate(t, data, cutpre, cutpost, downsample)
    # We want the positive frequencies after a simple fft to correspond to a
    # positive offset from the spectrometer reference frequency. But in twix
    # they are negative so directly doing an fft of the raw data would flip the
    # frequency axis.  We add a conj to standardize the convention.
    z = conj.(z)
    coilsyms = if isempty(expt.coils)
        [Symbol("C$i") for i in 1:length(acq.channel_info)]
    else
        # Match channels.
        #
        # This coil data appears to connect to the measurement data via the
        # channel header channel_id field, when the relation
        #
        #     channel_id-1 == adc_channel_connected
        #
        # holds. Why the -1 is here is a mystery - perhaps the channel_id field
        # uses 1-based indexing.
        [Symbol(expt.coils[findfirst(e->e.adc_channel_connected-1 == c.channel_id, expt.coils)].element)
         for c in acq.channel_info]
    end
    channel_ids = [Int(c.channel_id) for c in acq.channel_info]
    AxisArray(z, Axis{:time}(t), Axis{:channel}(coilsyms))
end


"""
    mr_load(twix::MRExperiment)

Recognizes spectro experiments in Siemens twix format, producing one of:
  * LCOSY
  * PRESS (TODO)
"""
function mr_load(twix::MRExperiment)
    @debug "Recognizing twix input" twix

    meta = standard_metadata(twix)
    @debug "Found standard metadata" meta

    is_svs_lcosy = occursin("svs_lcosy", meta.sequence_name)
    is_srcosy    = occursin("srcosy", meta.sequence_name) ||
                   occursin("sr_cosy", meta.sequence_name)
    if is_svs_lcosy || is_srcosy
        release_versions = ["%CustomerSeq%\\srcosy",
                            "%CustomerSeq%\\sr_cosy",
                            "%CustomerSeq%\\svs_lcosy-1"]
        if !(meta.sequence_name in release_versions)
            @warn """
                  Sequence `$(meta.sequence_name)` looks like an L-COSY sequence,
                  but is not one of the versions I recognize. We will continue
                  trying to read the data but if it's a development version of
                  the sequence you might get strange results.
                  """  meta.sequence_name twix
        end

        num_averages = twix.metadata["lAverages"]

        t1_inc_loop_idx = 0

        if is_srcosy
            old_srcosy = occursin("sr_cosy", meta.sequence_name) ||
                         occursin("N4_VD", meta.software_version)
            # Uuugh. Number of t1 increments must be inferred from repetitions
            # loop counter.
            t1_inc_loop_idx = loop_counter_index(:repetition)
            nsamp_t1 = Int(maximum(d.loop_counters.repetition for d in twix.data)) + 1
            dt1_key = "sWipMemBlock.adFree[1]"
            if !haskey(twix.metadata, dt1_key)
                # Guuuuh! It gets worse. It seems that likely that for this
                # very old sr_cosy sequence data we have no `dt1` value in the
                # WIP mem block. Probably it was just hardcoded so we will have
                # to guess.
                # TODO: Check this!!!
                dt1 = 0.8u"ms"
                #if !old_srcosy # TODO.
                    @warn """
                          No T1 increment found in twix metadata. We are guessing a value of `$dt1`.
                          """ meta
                #end
            else
                dt1 = twix.metadata[dt1_key]*u"ms"
            end
        elseif is_svs_lcosy
            nsamp_t1 = twix.metadata["sWipMemBlock.alFree[3]"]
            t1_inc_loop_idx = loop_counter_index(:partition)
            # TODO - stash legacy_timing somewhere
            legacy_timing = get(twix.metadata, "sWipMemBlock.alFree[5]", 0) == 1
            dt1           = twix.metadata["sWipMemBlock.adFree[1]"]*u"ms"
        end

        TE = get(twix.metadata,"alTE[0]", 0)u"μs"
        if TE != 30000u"μs"
            @warn "Found unexpected TE=$TE in L-COSY sequence"
        end

        has_refscans = get(twix.metadata, "sSpecPara.lAutoRefScanMode", 1) != 1

        ref_scans = Int[]
        lcosy_scans = zeros(Int, num_averages, nsamp_t1)

        did_loop_warning = false
        for (i,acq) in enumerate(twix.data)
            if !has_refscans && acq.loop_counters.phase != 0
                @warn """
                      Phase loop is nonzero but AutoRefScanMode is OFF.
                      I don't know what to do with this acquisition!
                      """
                continue
            end
            is_refscan = has_refscans && acq.loop_counters.phase == 0
            if is_refscan
                push!(ref_scans, i)
            end
            t1_index = acq.loop_counters[t1_inc_loop_idx] + 1
            avg_index = acq.loop_counters.acquisition + 1
            if avg_index == 1 && acq.loop_counters.set > 0
                avg_index = acq.loop_counters.set + 1
                if !did_loop_warning
                    # There's two possibilities here.
                    # 1) VD13A and older data have a different ABI for twix,
                    #    with the loop order switched.
                    # 2) `set` was used for spectro averaging in the older software.
                    # TODO: Figure out which one of these it was, and remove this warning!
                    @warn """
                          We're guessing that the averaging loop is using the
                          `set` loop counter for this twix version.
                          """ metadata=meta
                    did_loop_warning = true
                end
            end
            lcosy_scans[avg_index, t1_index] = i
        end

        if any(lcosy_scans .== 0)
            nmissing = length(findall(lcosy_scans .== 0))
            error("Missing increments or averages in L-COSY scan ($nmissing of $(length(lcosy_scans)))")
        end

        t1 = (0:nsamp_t1-1)*dt1
        return LCOSY(t1, meta, ref_scans, lcosy_scans, twix)
    end

    error("Siemens raw data with sequence \"$(meta.sequence_name)\" is unrecognized")
end

