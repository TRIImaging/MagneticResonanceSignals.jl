"""
    felix_header(; npoints, bandwidth, frequency)

Create Felix NMR header format for 2D NMR experiment with 2D data matrix size
`npoints = (t2_npoints, t1_npoints)`, spectral width `bandwidth = (t2_bw,
t1_bw)` and given spectrometer `frequency` (unit-compatible with Hz).


# Notes about Felix .dat formats.

The Felix `.dat` format exists to convey raw spectrometer data, spectrometer
configuration and processing parameters to Felix. Felix variables can be
listed within the Felix interface by typing the `lis` ("list symbols")
command.  See <www.felixnmr.com/doc/felix2004L/cref/Output/A_CommandRef_1_all.html>.

Unfortunately `.dat` is rather poorly documented.  Here's what I (Chris
Foster) have been able to deduce about it by looking at old source code and
writing exploratory data files followed by dumping the Felix symbols with the
`lis` command.

`.dat` comes in two (or perhaps three?) flavours:

1. Felix "old .dat format": A format based on FORTRAN sequential, unformatted
   access which is system dependent, with the exact detail depending on the
   system FORTRAN compiler.  We don't deal with this format here, but you can
   look in the GAMMA NMR simulator for a certian amount of example code. It's
   unknown whether Felix2007 can still deal with this format.

2. Felix "new .dat format": A format which is machine and compiler
   independent, and which comes in "frames" (each defining a dimension?),
   rather poorly documented in fxrw.c and wn.f files which come in the felix
   distribution at `gifts/felix/newformat`, and slightly better documented by
   `gifts/felix/BRUKER/mips/ux2flx.f`.  Felix appears to use this format if
   you use "Process1D->Open and Process".

3. Multidimensional `.dat` format for Felix2007: A machine/compiler
   independent format defining parameters for multidimensional NMR
   experiments up to 6 dimensions. This appears to have the same pre-header
   as format 2 above, and it's unclear whether this is distinct or part of
   the same thing. Felix seems to use this for "ProcessND->Open and Process 2D".

We partially implement format 3 here.
"""
function felix_header(; npoints, bandwidth, frequency)
    # Initial part of header
    iwords = zeros(UInt32, 256)

    iwords[1] = 1    # number of frames
    iwords[2] = 0    # data format (0 = IEEE floating point,  1 = 32-bit integer)
    iwords[3] = 1    # ?
    iwords[4] = 32   # frame size
    iwords[5] = 210  # Felix Version number

    fwords = reinterpret(Float32, iwords)

    # ---------------------- 1D data section ------------------------
    # Section for 1D data ??
    # Still doesn't seem quite right...
    iwords[96] = npoints[1]  # number of points
    iwords[97] = 1          # data type (0=real, 1=complex, 2=integer)
    #iwords[98] = domain      # domain (0=time, 1=frequency)
    #iwords[99] = axtype      # axis type (0=none, 1=points, 3=ppm)
    # For 1D?
    fwords[111] = ustrip(u"Hz", bandwidth[1]) # swidth
    fwords[112] = ustrip(u"MHz", frequency)   # sfreq
    #fwords[113] = refpt       # refpt
    #fwords[114] = refHz       # ref
    #fwords[116] = phase0[1]
    #fwords[117] = phase1[1]

    # Old bruker dsp acqusition "decimation" params
    #iwords[118] = dspfvs
    #iwords[119] = decim
    #iwords[120] = grpdly

    # ---------------------- 2D data section ------------------------
    # Need to set the following value to 1, or felix won't read the
    # parameters further down. Is this a flag for ND data?
    iwords[121] = 1

    # The names of parameters on the right hand side here are the names of the
    # associated variables inside Felix.

    # Data size
    iwords[122] = npoints[1]  # nacqs1
    iwords[123] = npoints[2]  # nacqs2
    #iwords[124] = nacqs3
    #iwords[125] = nacqs4
    #iwords[126] = nacqs5
    #iwords[127] = nacqs6

    # Complex vs real acquisition flag "quadf == Quadrature Flag?"
    iwords[128:133] .= 1
    #iwords[128] = quadf1
    #iwords[129] = quadf2
    #iwords[130] = quadf3
    #iwords[131] = quadf4
    #iwords[132] = quadf5
    #iwords[133] = quadf6

    # Spectrometer Frequency (in MHz)  a1rsf1 ... a1rsf6
    fwords[134] = ustrip(u"MHz", frequency)
    fwords[135] = ustrip(u"MHz", frequency)
    #fwords[136] = a1rsf3
    #fwords[137] = a1rsf4
    #fwords[138] = a1rsf5
    #fwords[139] = a1rsf6

    # Sweep width (Hz)   # a1rsw1 .. a1rsw6
    fwords[140] = ustrip(u"Hz", bandwidth[1])
    fwords[141] = ustrip(u"Hz", bandwidth[2])
    #fwords[142] = a1rsw3
    #fwords[143] = a1rsw4
    #fwords[144] = a1rsw5
    #fwords[145] = a1rsw6

    # Spectral referencing (refpt / refHz
    #fwords[146] = a1rpv1
    #fwords[147] = a1rpv2
    #fwords[148] = a1rpv3
    #fwords[149] = a1rpv4
    #fwords[150] = a1rpv5
    #fwords[151] = a1rpv6
    #fwords[152] = a1rpn1
    #fwords[153] = a1rpn2
    #fwords[154] = a1rpn3
    #fwords[155] = a1rpn4
    #fwords[156] = a1rpn5
    #fwords[157] = a1rpn6

    # Phase correction params
    #fwords[158] = d1ph0
    #fwords[159] = d1ph1
    #fwords[160] = d2ph0
    #fwords[161] = d2ph1
    #fwords[162] = d3ph0
    #fwords[163] = d3ph1
    #fwords[164] = d4ph0
    #fwords[165] = d4ph1
    #fwords[166] = d5ph0
    #fwords[167] = d5ph1
    #fwords[168] = d6ph0
    #fwords[169] = d6ph1

    # ?
    #iwords[170] = splmod
    #iwords[171] = qrtord

    # Temperature
    #fwords[172] = rtemp

    # Date and acqusition session
    #iwords[173] = crmon
    #iwords[174] = crday
    #iwords[175] = cryear
    #iwords[176] = acqsch
    #iwords[177] = aqmod1
    #iwords[178] = aqmod2
    #iwords[179] = aqmod3
    #iwords[180] = aqmod4
    #iwords[181] = aqmod5
    #iwords[182] = aqmod6

    # ???
    #iwords[183] = fflag1
    #iwords[184] = fflag2
    #iwords[185] = fflag3
    #iwords[186] = fflag4
    #iwords[187] = fflag5
    #iwords[188] = fflag6

    iwords
end

function write_felix_data(io, data)
    for i=1:size(data,2)
        # We add a `conj` here because Felix seems to expect positive
        # frequencies to be negative offsets from the spectrometer reference.
        # (TODO: Maybe this is the standard convention for NMR data? It seems
        # confusing.)
        fid = conj.(ComplexF32.(data[:,i]))
        # Felix format counts data in 32-bit words
        nwords = 2*length(fid)
        write(io, convert(Int32, nwords))
        write(io, fid)
    end
end

"""
    save_felix(fname, data; bandwidth, frequency)

Create Felix NMR file for 2D NMR experiment with 2D data matrix size
`npoints = size(data)`, spectral width `bandwidth = (t2_bw, t1_bw)` and given
spectrometer `frequency`, which should be unit-compatible with Hz.

`data[i,:]` is assumed to contain the real time FIDs as acquired in the
standard 2D COSY experiment (ie, the "t2" dimension).
"""
save_felix(fname::String, data; kwargs...) = open(fname, "w") do io
    save_felix(io, data; kwargs...)
end

function save_felix(io::IO, data; bandwidth, frequency)
    header = felix_header(npoints=size(data), bandwidth=bandwidth, frequency=frequency)

    # Endian marker
    write(io, UInt32(0x04030201))
    # Header size
    write(io, UInt32(length(header)))
    # Header data
    write(io, header)

    write_felix_data(io, data)
end

#-------------------------------------------------------------------------------
#=
"""
Read a spectrum file in Felix ".mat" format

(Felix is software for 2D spectroscopy.)
"""
function read_felix_spectrum(fname)
    @warn "read_felix_spectrum is mostly untested!" max_log=1
    header,rawdata = open(fname) do io
        read(io, 2^14), read(io, 2^22)
    end

    # Felix spectral data appears to be stored in big endian Float32 in the last
    # section of the file.
    #
    # Furthermore, the data layout is not a simple strided matrix, but looks like a
    # set of 128x32 image tiles.
    #
    # It also looks like this data might be magnitude only (??)
    tilesize = (128,32)
    ntiles = (16,16)
    spectrum_size = tilesize .* ntiles
    data_tiles = reshape(ntoh.(reinterpret(Float32, rawdata)), tilesize..., ntiles...)

    # Reshape data from tiled format into a normal strided format
    reshape(permutedims(data_tiles, (1,3,2,4)), spectrum_size...)
end
=#
