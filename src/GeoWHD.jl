"""
# GeoWHD

This package provides various functions for merging WHD geospatial data with BLS data. It allows users to easily retrieve, analyze, and visualize
 BLS data, based on WHD geographies.

## Example Usage
```julia
using GeoWHD
using DataFrames

# Get office names
office_names = get_office_names()
regional_offices = office_names.regional_offices
district_offices = office_names.district_offices

# Get Local Area Unemployment Statistics (LAUS) data for the Seattle District Office
seattle_laus = LAUS("Seattle District Office")

# Plot the most recent unemployment rate by district office
unemployment = DataFrame(
    office=district_offices,
    unemployment_rate=[LAUS(ofc)[end, :unemployment_rate] for ofc in district_offices]
)

do_heatmap(unemployment; office_col=:office, data_col=:unemployment_rate, color_scheme=:reds)
```
## Functions
- `LAUS`: Retrieves LAUS data for a given office.
- `OEWS`: Retrieves OEWS data for a given office.
- `QCEW`: Retrieves QCEW data for a given office.
- `do_heatmap`: Creates District Office heatmaps.
- `ro_heatmap`: Creates Regional Office heatmaps.
- `msa_heatmap`: Create MSA heatmaps which include WHD District Office information.
- `get_msas`: Retrieve the MSA IDs.
- `get_office_names`: Retrieves the names of the offices.
"""
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
const ces_series = Ref{Union{Nothing,DataFrame}}(nothing)
const ces_data = Ref{Union{Nothing,DataFrame}}(nothing)

export CES
export LAUS
export OEWS
export QCEW
export get_office_names
export do_heatmap
export do_county_heatmap
export do_msa_heatmap
export ro_heatmap
export ro_msa_heatmap
export get_msas
export msa_heatmap
export county_heatmap

end