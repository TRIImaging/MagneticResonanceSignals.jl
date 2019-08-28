#!/usr/bin/env julia

using TriMRS
using Statistics
using Unitful
using AxisArrays

# TODO: Move the signal processing parts (at least!) into src!
function twix_to_felix(twixname, felixname; repair=false)
    twix = load_twix(twixname)
    spectro = mr_load(twix; repair=repair)
    @info "Opened data file" twixname spectro

    signal = simple_averaging(spectro, downsample=2)

    # Extract some metadata required by the felix format
    frequency = standard_metadata(spectro).frequency
    f1_bandwidth = 1.0/step(AxisArrays.axes(signal, Axis{:time1}).val)
    f2_bandwidth = 1.0/step(AxisArrays.axes(signal, Axis{:time2}).val)

    save_felix(felixname, signal; bandwidth=(f2_bandwidth, f1_bandwidth), frequency=frequency)

    @info "Wrote to Felix file $felixname"
    signal
end

using ArgParse

argdef = ArgParseSettings(exc_handler=isinteractive() ? ArgParse.debug_handler : ArgParse.default_handler)
@add_arg_table argdef begin
    "--repair"
        help = "Attempt to repair a partially complete LCOSY sequence"
        action = :store_true
    "in_file"
        help = "path to the input twix file (Siemens meas_*.dat RAID format)"
        required = true
    "out_file"
        help = "path to the output file (Felix .dat format)."
        required = true
end

function process_args(argvec)
    parsed_args = parse_args(argvec, argdef)

    in_file = parsed_args["in_file"]
    out_file = parsed_args["out_file"]

    (in_file=in_file, out_file=out_file, repair=parsed_args["repair"])
end


args = process_args(ARGS)
twix_to_felix(args.in_file, args.out_file, repair=args.repair)
