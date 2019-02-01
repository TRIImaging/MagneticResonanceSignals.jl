#!/usr/bin/env julia

using TriMRS
using Statistics
using Unitful
using AxisArrays

# TODO: Move the signal processing parts (at least!) into src!
function twix_to_felix(twixname, felixname)
    twix = load_twix(twixname)
    @info "Opened twix file" twixname twix

    frequency = twix.metadata["sTXSPEC.asNucleusInfo[0].lFrequency"]*u"Hz"

    num_t1_incs  = twix.metadata["sWipMemBlock.alFree[3]"]
    num_averages = twix.metadata["lAverages"]
    dt1          = twix.metadata["sWipMemBlock.adFree[1]"]*1e-3u"s"

    combiner = pca_channel_combiner(twix.data)
    t2_ax = AxisArrays.axes(sampledata(twix,1, downsample=2), Axis{:time})
    t1_val = (0:num_t1_incs-1)*dt1
    nsamps = length(t2_ax)
    signal = AxisArray(zeros(ComplexF64, nsamps, num_t1_incs),
                       Axis{:time2}(t2_ax.val), Axis{:time1}(t1_val))
    for i=1:num_t1_incs
        scans_for_avg = (i-1)*num_averages .+ (1:num_averages)
        # FIXME: Remove this conj?
        fid = conj.(mean(combiner.(sampledata.(Ref(twix), scans_for_avg))))
        signal[:,i] = fid
    end

    f1_bandwidth = 1.0/dt1
    f2_bandwidth = 1.0/step(t2_ax.val)

    save_felix(felixname, signal; bandwidth=(f2_bandwidth, f1_bandwidth), frequency=frequency);

    @info "Wrote to Felix file $felixname"

    signal
end

using ArgParse

argdef = ArgParseSettings(exc_handler=isinteractive() ? ArgParse.debug_handler : ArgParse.default_handler)
@add_arg_table argdef begin
    "in_file"
        help = "path to the input twix file (Siemens meas_*.dat RAID format)"
        required = true
    "out_file"
        help = "path to the output file (Felix .dat format). By default, this will be derived from the path of the input."
end

function process_args(argvec)
    parsed_args = parse_args(argvec, argdef)

    in_file = parsed_args["in_file"]
    out_file = parsed_args["out_file"] !== nothing ?
               parsed_args["out_file"] :
               joinpath(dirname(in_file), "felix_"*splitext(basename(in_file))[1]*".dat")

    (in_file=in_file, out_file=out_file)
end


args = process_args(ARGS)
twix_to_felix(args.in_file, args.out_file)
