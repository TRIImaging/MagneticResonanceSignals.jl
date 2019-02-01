#!/usr/bin/env julia

# Script to extract twix headers into a new temporary directory

using TriMRS

twix=ARGS[1]
tmpdir = mktempdir(joinpath(homedir(), "tmp"))
TriMRS.dump_twix_headers(twix, tmpdir)
println(tmpdir)
