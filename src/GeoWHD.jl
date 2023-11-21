module GeoWHD

using CSV
using DataFramesMeta
using Dates
using Downloads
using HTTP
using JSON
using StringDistances
using VegaLite
using XLSX
using ZipFile

project_path(parts...) = normpath(joinpath(@__DIR__, "..", parts...))

include("structs.jl")
include("utils.jl")
include("data.jl")
include("methods.jl")

const offices = merge(regional_offices, district_offices)
const laus = Ref{Union{Nothing,DataFrame}}(nothing)
const qcew = Ref{Union{Nothing,DataFrame}}(nothing)
const oews_series = Ref{Union{Nothing,DataFrame}}(nothing)
const oews_data = Ref{Union{Nothing,DataFrame}}(nothing)

export LAUS
export get_office_names
export QCEW
export do_heatmap
export ro_heatmap
export OEWS
export get_msas
export msa_heatmap

end
