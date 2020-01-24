using MagneticResonanceSignals
using StaticArrays

function strip_twix_adjustment(in_file, out_file)
    open(in_file, "r") do src
        open(out_file, "w") do dest
            twix_id, num_measurements, mdata = MagneticResonanceSignals.read_meas_headers(src)

            # Create temp buffer
            buf = IOBuffer()

            @assert length(mdata) == 2 "Expected to have 2 measurements for adjustment and actual scan"
            meas = mdata[2]

            meas_offset = mdata[1].meas_offset

            # Change num_measurement to 1
            write(buf, SVector{2,Int32}(twix_id, 1))
            write(buf, meas.meas_uid)
            write(buf, meas.file_id)
            write(buf, meas_offset)
            write(buf, meas.meas_length)
            write(buf, meas.patient_name)
            write(buf, meas.protocol_name)

            # Seek to selected data
            seek(src, meas.meas_offset)

            write(buf, zeros(UInt8, meas_offset - position(buf)))
            @assert position(buf) == meas_offset
            write(buf, read(src, meas.meas_length))

            seekstart(buf)
            write(dest, read(buf))
        end
    end
end

using ArgParse

argdef = ArgParseSettings(exc_handler=isinteractive() ? ArgParse.debug_handler : ArgParse.default_handler,
                          prog="Twix Adjustment Remover",
                          description="""
                            Small program to remove adjustment data on Siemens twix, which relies heavily on MagneticResonanceSignals.
                            This program will take the in_file and write the no adjustment twix in out_file.
                            """)
@add_arg_table argdef begin
    "in_file"
        help = "path to the input twix file (Siemens meas_*.dat RAID format)"
        required = true
    "out_file"
        help = "path to the output file Siemens twix without adjustment data"
        required = true
end

function process_args(argvec)
    parsed_args = parse_args(argvec, argdef)

    in_file = parsed_args["in_file"]
    out_file = parsed_args["out_file"]

    (in_file=in_file, out_file=out_file)
end


args = process_args(ARGS)
strip_twix_adjustment(args.in_file, args.out_file)

