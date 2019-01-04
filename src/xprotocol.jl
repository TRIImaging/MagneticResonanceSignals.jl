"""
Parser utilities for `<XProtocol>`, presumably an internal Siemens metadata
protocol.
"""
#module XProtocol

using ParserCombinator

struct SimpleParam{T, Config<:NamedTuple}
    name::String
    config::Config
    vals::Vector{T}
end

function SimpleParam(type, name, config, vals)
    SimpleParam{type,typeof(config)}(name, config, collect(type, vals))
end

function Base.show(io::IO, param::SimpleParam{T}) where {T}
    print(io, "SimpleParam($T, $(repr(param.name)), $(param.config), $(param.vals))")
end


struct ParamMap{Config<:NamedTuple}
    name::String
    config::Config
    vals::Dict{Symbol,Any}
end

function ParamMap(name, config, vals)
    ParamMap{typeof(config)}(name, config, Dict(Symbol(p.name)=>p for p in vals))
end

function Base.show(io::IO, param::ParamMap)
    print(io, "ParamMap($(repr(param.name)), $(param.config), $(param.vals))")
end


spc = Drop(Star(Space()))
PString = E"\"" + p"[^\"]*" + E"\""
PBool = p"\"(true|false)\"" > (s -> s[2]=='t' ? true : false)

function brace_group(content)
    spc + E"{" + spc + content + spc + E"}"
end

function param_header(tag)
    Drop(Equal(string("<",tag,".\""))) + p"[^\"]*" + E"\">"
end

function param_config(type, Peltype)
    # Config elements.
    #
    # Each element is parsed as a pair `:key => val`, and the resulting list is
    # converted into a named tuple.
    Pstar_eltype = brace_group(Star(spc + Peltype)) |> make_vec(type)
    Ptwo_eltype = brace_group(Repeat(spc + Peltype, 2, 2)) |> make_vec(type)
    Pstar_any   = Peltype | PInt() | PString
    Pconfigelts =
        (
         ((E"<" + e"Default"     + E">" + spc) + Peltype)   |
         ((E"<" + e"Label"       + E">" + spc) + PString)   |
         ((E"<" + e"Visible"     + E">" + spc) + PString)   |
         ((E"<" + e"Unit"        + E">" + spc) + PString)   |
         ((E"<" + e"Comment"     + E">" + spc) + PString)   |
         ((E"<" + e"Tooltip"     + E">" + spc) + PString)   |
         ((E"<" + e"Precision"   + E">" + spc) + PInt())    |
         ((E"<" + e"MinSize"     + E">" + spc) + PInt())    |
         ((E"<" + e"MaxSize"     + E">" + spc) + PInt())    |
         ((E"<" + p"[^>]*"       + E">" + spc) + Pstar_any) >
         (n,v)->Symbol(n)=>v
        ) |
        (
         ((E"<" + e"Limit"       + E">" + spc) & Pstar_eltype) |
         ((E"<" + e"LimitRange"  + E">" + spc) & Ptwo_eltype)  |
         ((E"<" + p"[^>]*"       + E">" + spc) & Pstar_eltype) >
         (n,vs)->Symbol(n[1])=>vs[1]
        )

    Star(spc + Pconfigelts) |> a->(;a...)
end

make_vec(type) = vals->collect(type, vals)
make_simple_param(type) = function typed_param(name,config,vals...)
    SimpleParam(type, name, config, collect(type, vals))
end

simple_params = Any[]
for (prefix,type,Peltype) in [("ParamLong",   Int,     PInt()),
                              ("ParamDouble", Float64, PFloat64()),
                              ("ParamBool",   Bool,    PBool),
                              ("ParamString", String,  PString),
                              ("ParamChoice", String,  PString),
                             ]
    Pconfig = param_config(type, Peltype)

    # Name introducing the parameter
    Pname = param_header(prefix)

    # Parameter config and values
    Pvalues = brace_group(
        Pconfig +
        Star(spc + Peltype)
    )

    PParam = (Pname + Pvalues) > make_simple_param(type)
    push!(simple_params, PParam)
end

PParamMap = Delayed()
PParamMap.matcher = (param_header("ParamMap")                                   +
                     brace_group(param_config(Any, Alt(simple_params...))       +
                                 Star(spc + Alt(PParamMap, simple_params...)))) >
                    (name,config,vals...) -> ParamMap(name, config, vals)

# TODO:
#
# XProtocol
#   EVAStringTable
#   ProtocolComposer
#   Dependency
#
# PparamArray = 

#-------------------------------------------------------------------------------

input = """
      <ParamString."atTXCalibDate">
      {
        "20090304" "20090304" "" "" "" "" "" ""
      }



<ParamLong."IdPart">
{
0 0 0 0 0 0 0 0
}
        <ParamDouble."ApplCommon_Table_Position">
        {
          13.000
        }

              <ParamDouble."aflAmplitude">
              {
                <Precision> 6
                0.000000 0.000000 0.000000 0.000000 0.000000
              }

                      <ParamLong."lInlineEvaMode">
        {
          <Default> 1
          <Limit> { 1 2 4 8 16 32 64 128 256 512 1024 }
        }

        <ParamBool."MagnitudeImages">
        {
          <LimitRange> { "false" "true" }
          "true"
        }

        <ParamChoice."ucIntensity">
        {
          <Label> "Intensity"
          <Tooltip> "Intensity of Image Filtering"
          <Visible> "true"
          <Default> "Medium"
          <Limit> { "Sharp" "Medium" "Smooth" }
        }

    <ParamMap."readout">
    {
      <Comment> "Blah blah"

      <ParamDouble."dSag">
      {
        <Precision> 6
      }

      <ParamDouble."dCor">
      {
        <Precision> 6
      }

      <ParamDouble."dTra">
      {
        <Precision> 6
      }
    }

"""

param_array = """
      <ParamArray."alCoilPATMode">
      {
        <MinSize> 1
        <MaxSize> 128
        <Default> <ParamLong."">
        {
          <MinSize> 1
          <MaxSize> 128
          0 0 0 0 0 0 0 0
        }
        { <MinSize> 1  <MaxSize> 128  0 0 0 0 0 0 0 -1 -1 -1  -1 -1 -1 -1 -1 -1 -1 -1 -1 -1  -1 -1 -1 -1 -
1 -1 -1 -1 -1 -1  -1 -1 -1 -1 -1 -1 -1 -1 -1 -1  -1 -1 -1 -1 -1 -1 -1 -1 -1 -1  -1 -1 -1 -1 -1 -1 -1 -1 -1
 -1  -1 -1 -1 -1  }
        { <MinSize> 1  <MaxSize> 128  -1 -1 -1 -1 -1 -1 -1 -1 -1 -1  -1 -1 -1 -1 -1 -1 -1 -1 -1 -1  -1 -1
-1 -1 -1 -1 -1 -1 -1 -1  -1 -1 -1 -1 -1 -1 -1 -1 -1 -1  -1 -1 -1 -1 -1 -1 -1 -1 -1 -1  -1 -1 -1 -1 -1 -1 -
1 -1 -1 -1  -1 -1 -1 -1  }

      }
"""

parse_one(input, Plus(spc + Alt(PParamMap, simple_params...)))

#parse_one(param_map, PParamMap)

parse_one("""
          <ProtocolComposer."root">
          {
            <InFile> "A"
            <Dll> "B"
          }
          """,
          param_header("ProtocolComposer") + brace_group(Star(spc + E"<InFile>" + spc + PString)) >
              (n,vals...) -> (tag="ProtocolComposer", name=n, InFile=String.(vals))
)

