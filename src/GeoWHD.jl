module GeoWHD

using CSV
using DataFramesMeta
using Dates
using Downloads
using HTTP
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

export LAUS
export get_office_names
export QCEW
export do_heatmap

end
