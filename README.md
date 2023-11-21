# GeoWHD

[![Build Status](https://github.com/mthelm85/GeoWHD.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/mthelm85/GeoWHD.jl/actions/workflows/CI.yml?query=branch%3Amaster)

This package provides various functions for merging WHD geospatial data with BLS data. It allows users to easily retrieve, analyze, and visualize
 BLS data, based on WHD geographies.

## Example Usage
```julia
using GeoWHD
using DataFrames

# Get office names
office_names = get_office_names()
regional_offices = office_names.regional.offices
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
- `OEWS`: Exported symbol that represents the `oews_series` constant.
- `QCEW`: Retrieves QCEW data for a given office.
- `do_heatmap`: Creates District Office heatmaps.
- `ro_heatmap`: Creates Regional Office heatmaps.
- `msa_heatmap`: Create MSA heatmaps which include WHD District Office information.
- `get_msas`: Retrieve the MSA IDs.
- `get_office_names`: Retrieves the names of the offices.