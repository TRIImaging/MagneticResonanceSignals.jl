#!/bin/bash
#=
exec julia --project=. -e 'include(popfirst!(ARGS))' \
    "${BASH_SOURCE[0]}" "$@"
=#

# Script to extract twix headers into a new temporary directory

using ArgParse

argdef = ArgParseSettings(exc_handler=isinteractive() ? ArgParse.debug_handler : ArgParse.default_handler)
@add_arg_table argdef begin
    "in_file"
        help = "path to the input twix file (Siemens meas_*.dat RAID format)"
        required = true
    "out_dir"
        help = "path to the output directory"
        required = true
end

parsed_args = parse_args(ARGS, argdef)

using MagneticResonanceSignals
out_dir = parsed_args["out_dir"]
if !isdir(out_dir)
    mkpath(out_dir)
end
MagneticResonanceSignals.dump_twix_headers(parsed_args["in_file"], out_dir)
