module GeoWHD

using CSV
using DataFramesMeta
using Dates
using HTTP
using StringDistances

project_path(parts...) = normpath(joinpath(@__DIR__, "..", parts...))

include("structs.jl")
include("data.jl")
include("methods.jl")

const offices = merge(regional_offices, district_offices)

const laus = Ref{Union{Nothing,DataFrame}}(nothing)

export LAUS
export get_office_names

end
