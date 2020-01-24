nmrpipe_header_fields = [
  # name               type               word offset (4-byte words)
    ("FDMAGIC",        Float32,           0),
    ("FDFLTFORMAT",    Float32,           1),
    ("FDFLTORDER",     Float32,           2),
    ("FDDIMCOUNT",     Float32,           9),
    ("FDF3OBS",        Float32,           10),
    ("FDF3SW",         Float32,           11),
    ("FDF3ORIG",       Float32,           12),
    ("FDF3FTFLAG",     Float32,           13),
    ("FDPLANELOC",     Float32,           14),
    ("FDF3SIZE",       Float32,           15),
    ("FDF2LABEL",      FixedString{8},    16),
    ("FDF1LABEL",      FixedString{8},    18),
    ("FDF3LABEL",      FixedString{8},    20),
    ("FDF4LABEL",      FixedString{8},    22),
    ("FDDIMORDER1",    Float32,           24),
    ("FDDIMORDER2",    Float32,           25),
    ("FDDIMORDER3",    Float32,           26),
    ("FDDIMORDER4",    Float32,           27),
    ("FDF4OBS",        Float32,           28),
    ("FDF4SW",         Float32,           29),
    ("FDF4ORIG",       Float32,           30),
    ("FDF4FTFLAG",     Float32,           31),
    ("FDF4SIZE",       Float32,           32),
    ("FDF3APOD",       Float32,           50),
    ("FDF3QUADFLAG",   Float32,           51),
    ("FDF4APOD",       Float32,           53),
    ("FDF4QUADFLAG",   Float32,           54),
    ("FDF1QUADFLAG",   Float32,           55),
    ("FDF2QUADFLAG",   Float32,           56),
    ("FDPIPEFLAG",     Float32,           57),
    ("FDF3UNITS",      Float32,           58),
    ("FDF4UNITS",      Float32,           59),
    ("FDF3P0",         Float32,           60),
    ("FDF3P1",         Float32,           61),
    ("FDF4P0",         Float32,           62),
    ("FDF4P1",         Float32,           63),
    ("FDF2AQSIGN",     Float32,           64),
    ("FDPARTITION",    Float32,           65),
    ("FDF2CAR",        Float32,           66),
    ("FDF1CAR",        Float32,           67),
    ("FDF3CAR",        Float32,           68),
    ("FDF4CAR",        Float32,           69),
    ("FDUSER1",        Float32,           70),
    ("FDUSER2",        Float32,           71),
    ("FDUSER3",        Float32,           72),
    ("FDUSER4",        Float32,           73),
    ("FDUSER5",        Float32,           74),
    ("FDPIPECOUNT",    Float32,           75),
    ("FDFIRSTPLANE",   Float32,           77),
    ("FDLASTPLANE",    Float32,           78),
    ("FDF2CENTER",     Float32,           79),
    ("FDF1CENTER",     Float32,           80),
    ("FDF3CENTER",     Float32,           81),
    ("FDF4CENTER",     Float32,           82),
    ("FDF2APOD",       Float32,           95),
    ("FDF2FTSIZE",     Float32,           96),
    ("FDREALSIZE",     Float32,           97),
    ("FDF1FTSIZE",     Float32,           98),
    ("FDSIZE",         Float32,           99),
    ("FDF2SW",         Float32,           100),
    ("FDF2ORIG",       Float32,           101),
    ("FDQUADFLAG",     Float32,           106),
    ("FDF2ZF",         Float32,           108),
    ("FDF2P0",         Float32,           109),
    ("FDF2P1",         Float32,           110),
    ("FDF2LB",         Float32,           111),
    ("FDF2OBS",        Float32,           119),
    ("FDMCFLAG",       Float32,           135),
    ("FDF2UNITS",      Float32,           152),
    ("FDNOISE",        Float32,           153),
    ("FDTEMPERATURE",  Float32,           157),
    ("FDRANK",         Float32,           180),
    ("FDTAU",          Float32,           199),
    ("FDF3FTSIZE",     Float32,           200),
    ("FDF4FTSIZE",     Float32,           201),
    ("FDF1OBS",        Float32,           218),
    ("FDSPECNUM",      Float32,           219),
    ("FDF2FTFLAG",     Float32,           220),
    ("FDTRANSPOSED",   Float32,           221),
    ("FDF1FTFLAG",     Float32,           222),
    ("FDF1SW",         Float32,           229),
    ("FDF1UNITS",      Float32,           234),
    ("FDF1LB",         Float32,           243),
    ("FDF1P0",         Float32,           245),
    ("FDF1P1",         Float32,           246),
    ("FDMAX",          Float32,           247),
    ("FDMIN",          Float32,           248),
    ("FDF1ORIG",       Float32,           249),
    ("FDSCALEFLAG",    Float32,           250),
    ("FDDISPMAX",      Float32,           251),
    ("FDDISPMIN",      Float32,           252),
    ("FD2DPHASE",      Float32,           256),
    ("FDF2X1",         Float32,           257),
    ("FDF2XN",         Float32,           258),
    ("FDF1X1",         Float32,           259),
    ("FDF1XN",         Float32,           260),
    ("FDF3X1",         Float32,           261),
    ("FDF3XN",         Float32,           262),
    ("FDF4X1",         Float32,           263),
    ("FDF4XN",         Float32,           264),
    ("FDHOURS",        Float32,           283),
    ("FDMINS",         Float32,           284),
    ("FDSECS",         Float32,           285),
    ("FDSRCNAME",      FixedString{16},   286),
    ("FDUSERNAME",     FixedString{16},   290),
    ("FDMONTH",        Float32,           294),
    ("FDDAY",          Float32,           295),
    ("FDYEAR",         Float32,           296),
    ("FDTITLE",        FixedString{60},   297),
    ("FDCOMMENT",      FixedString{160},  312),
    ("FDLASTBLOCK",    Float32,           359),
    ("FDCONTBLOCK",    Float32,           360),
    ("FDBASEBLOCK",    Float32,           361),
    ("FDPEAKBLOCK",    Float32,           362),
    ("FDBMAPBLOCK",    Float32,           363),
    ("FDHISTBLOCK",    Float32,           364),
    ("FD1DBLOCK",      Float32,           365),
    ("FDF2TDSIZE",     Float32,           386),
    ("FDF1TDSIZE",     Float32,           387),
    ("FDF3TDSIZE",     Float32,           388),
    ("FDF4TDSIZE",     Float32,           389),
    ("FD2DVIRGIN",     Float32,           399),
    ("FDF3APODCODE",   Float32,           400),
    ("FDF3APODQ1",     Float32,           401),
    ("FDF3APODQ2",     Float32,           402),
    ("FDF3APODQ3",     Float32,           403),
    ("FDF3C1",         Float32,           404),
    ("FDF4APODCODE",   Float32,           405),
    ("FDF4APODQ1",     Float32,           406),
    ("FDF4APODQ2",     Float32,           407),
    ("FDF4APODQ3",     Float32,           408),
    ("FDF4C1",         Float32,           409),
    ("FDF2APODCODE",   Float32,           413),
    ("FDF1APODCODE",   Float32,           414),
    ("FDF2APODQ1",     Float32,           415),
    ("FDF2APODQ2",     Float32,           416),
    ("FDF2APODQ3",     Float32,           417),
    ("FDF2C1",         Float32,           418),
    ("FDF1APODQ1",     Float32,           420),
    ("FDF1APODQ2",     Float32,           421),
    ("FDF1APODQ3",     Float32,           422),
    ("FDF1C1",         Float32,           423),
    ("FDF1APOD",       Float32,           428),
    ("FDF1ZF",         Float32,           437),
    ("FDF3ZF",         Float32,           438),
    ("FDF4ZF",         Float32,           439),
    ("FDFILECOUNT",    Float32,           442),
    ("FDSLICECOUNT",   Float32,           443),
    ("FDOPERNAME",     FixedString{32},   464),
    ("FDF1AQSIGN",     Float32,           475),
    ("FDF3AQSIGN",     Float32,           476),
    ("FDF4AQSIGN",     Float32,           477),
    ("FDF2OFFPPM",     Float32,           480),
    ("FDF1OFFPPM",     Float32,           481),
    ("FDF3OFFPPM",     Float32,           482),
    ("FDF4OFFPPM",     Float32,           483),
]

function write_nmrpipe_data(io, signal, indirect_axis, direct_axis)
    @assert ndims(signal) == 2
    for i = size(signal, indirect_axis()):-1:1
        fid = signal[indirect_axis(i), direct_axis(:)]
        write(io, Float32.(real.(fid)))
        write(io, Float32.(imag.(fid)))
    end
end

function write_nmrpipe_data(io, signal, direct_axis)
    @assert ndims(signal) == 1
    write(io, Float32.(real.(signal)))
    write(io, Float32.(imag.(signal)))
end

#=
# TODO unified 1D & 2D stuff
function add_nmrpipe_header_axis_info(header, ax, obs_freq, car_ppm)
    # Single axis shared stuff
end

function add_nmrpipe_header_axes(header, signal, indirect_axis, direct_axis)
    # 1D dimension-specific header stuff
end

function add_nmrpipe_header_axes(header, signal, indirect_axis, direct_axis)
    # 2D dimension-specific header stuff
end
=#

"""
    save_nmrpipe(io, signal, axes; frequency, ref_freq_offset)

Convert twix into NMR Pipe format to be loaded into third party analytical
software, such as MNova. This currently supports up to 2 dimension.

At minimal, for each dimension we should have:
- Signal data
- Axes
- Observation frequency (frequency)
- Carrier frequency (`ref_freq_offset`)

`ref_freq_offset` is a tuple containing the relative frequency offset between
obs_freq and frequency which will be set to 0 on the ppm scale.
"""
function save_nmrpipe(io::IO, signal, axes; frequency, ref_freq_offset)
    ndim = ndims(signal)

    if ndim != 2
        error("Only 2 dimensional data is currently supported")
    end

    # f1 and f2 bandwidth
    indirect_axis, direct_axis = axes
    f1_bandwidth = ustrip(u"Hz", 1.0/step(AxisArrays.axes(signal, indirect_axis).val))
    f2_bandwidth = ustrip(u"Hz", 1.0/step(AxisArrays.axes(signal, direct_axis).val))

    # frequency
    obs_freq       = ustrip(u"MHz", frequency)
    car_f1, car_f2 = ustrip.(u"ppm", ref_freq_offset)
    is_complex_data = true # Our data is complex data
    encoding       = "magnitude"
    time_domain    = true # Our data is always time domain

    # Construct dictionary of NMR Pipe header
    data = Dict()

    # Assign default values
    data["FDF1CENTER"] = 1.
    data["FDF2CENTER"] = 1.
    data["FDF3CENTER"] = 1.
    data["FDF4CENTER"] = 1.

    data["FDF3SIZE"] = 1.
    data["FDF4SIZE"] = 1.

    data["FDF1QUADFLAG"] = 1.
    data["FDF2QUADFLAG"] = 1.
    data["FDF3QUADFLAG"] = 1.
    data["FDF4QUADFLAG"] = 1.

    data["FDSPECNUM"]   = 1.
    data["FDFILECOUNT"] = 1.
    data["FD2DVIRGIN"]  = 1.
    # dimention ordering

    data["FDDIMORDER1"] = 2.0
    data["FDDIMORDER2"] = 1.0
    data["FDDIMORDER3"] = 3.0
    data["FDDIMORDER4"] = 4.0

    data["FDF1LABEL"] = "Y"
    data["FDF2LABEL"] = "X"
    data["FDF3LABEL"] = "Z"
    data["FDF4LABEL"] = "A"

    # misc values
    # fdatap.h says this "Indicates IEEE floating point format"
    data["FDFLTFORMAT"] = read(IOBuffer(b"\xef\xeenO"), Float32)
    data["FDFLTORDER"]  = 2.345f0  # Byte order mark (as a Float32!)

    data["FDDIMCOUNT"]  = ndim

    data["FDF1SW"] = f1_bandwidth
    data["FDF2SW"] = ndim > 1 ? f2_bandwidth : nothing

    if ndim > 1
        for ax in 1:ndim
            data["FDF$(ax)OBS"] = obs_freq
            data["FDF$(ax)CAR"] = ax == 1 ? car_f1 : car_f2
            data["FDF$(ax)QUADFLAG"] = is_complex_data ? 0.0 : 1.0
            psize = is_complex_data && (ax != 1) ?
                    size(signal, indirect_axis)/2 : size(signal, direct_axis)/1
            osize = psize
            data["FDF$(ax)TDSIZE"] = psize
            data["FDF$(ax)FTFLAG"] = time_domain == true ? 0.0 : 1.0
            data["FDF$(ax)APOD"] = data["FDF$(ax)TDSIZE"]

            if encoding == "tppi"
                data["FD$(ax)DPHASE"] = 1.0
            elseif (encoding == "complex") || (encoding == "states") || (encoding == "states-tppi")
                data["FD$(ax)DPHASE"] = 2.0
            else
                data["FD$(ax)DPHASE"] = 0.0
            end

            data["FDF$(ax)CENTER"] = (ax == 1) || (data["FD$(ax)DPHASE"] != 1) ?
                                     Int(psize/2.0) + 1.0 : Int(psize/4.0) + 1
            data["FDF$(ax)ORIG"] = data["FDF$(ax)CAR"] * data["FDF$(ax)OBS"] - data["FDF$(ax)SW"] * (osize - data["FDF$(ax)CENTER"]) / osize

            if ax == 1
                data["FDSIZE"] = psize
                data["FDREALSIZE"] = psize
            end
            if ax == 2
                data["FDSPECNUM"] = size(signal, indirect_axis)
                data["FDF1AQSIGN"] = (encoding == "complex") || (encoding == "states") ? 0 : 16
            end
        end
    end

    # Write binary header
    nmrpipe_word_size = 4
    buf = IOBuffer(zeros(UInt8, 512*nmrpipe_word_size), write=true, truncate=false, read=true)
    for (key,type,offset) in nmrpipe_header_fields
        if haskey(data, key)
            seek(buf,  nmrpipe_word_size*offset)
            write(buf, type(data[key]))
        end
    end
    seek(buf, 0)
    write(io, buf)
    write_nmrpipe_data(io, signal, axes...)
    nothing
end

function save_nmrpipe(filename::AbstractString, args...; kws...)
    open(filename, "w") do io
        save_nmrpipe(io, args...; kws...)
    end
end

_open(f, io::IO, args...) = f(io)
_open(f, name::AbstractString, args...; kws...) = open(f, name, args...; kws...)


"""
    twix_to_nmrpipe(twix, nmrpipe_path)

`twix` is a path or open IO stream to the original twix data file.
`nmrpipe` is a path or open IO stream to the result file to be written.
"""
function twix_to_nmrpipe(twix, nmrpipe)
    _open(twix) do twix_io
        twix_data = load_twix(twix_io)
        expt = mr_load(twix_data)
        signal = simple_averaging(expt, downsample=2)

        frequency = standard_metadata(twix_data).frequency

        _open(nmrpipe, "w") do nmrpipe_io
            save_nmrpipe(nmrpipe_io, signal, (Axis{:time1}, Axis{:time2});
                         frequency=frequency,
                         ref_freq_offset=(_water_tms_offset, _water_tms_offset))
        end
    end
end

