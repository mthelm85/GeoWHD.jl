function OEWS(office::DistrictOffice)
    series = @chain oews_series[] begin
        @rsubset(:area_code in do_msas(office))
    end
    return leftjoin(series, oews_data[]; on=:series_id, makeunique=true)
end

function OEWS(office::RegionalOffice)
    series = @chain oews_series[] begin
        @rsubset(:area_code in region_msas(office))
    end
    return leftjoin(series, oews_data[]; on=:series_id, makeunique=true)
end

function OEWS(occupation_code::Int)
    if isnothing(oews_series[])
        oews_series[] = get_oews_series()
    end
    if isnothing(oews_data[])
        oews_data[] = get_oews_data()
    end
    series = @chain oews_series[] begin
        @rsubset(:occupation_code == occupation_code)
    end
    return leftjoin(series, oews_data[]; on=:series_id, makeunique=true)
end

"""
    OEWS(office::String)

Retrieve the most recent OEWS (Occupational Employment and Wage Statistics) data for a specific office.

## Arguments
- `office::String`: The name of the office for which OEWS data is requested. Can be a regional or district office.

## Returns
A `DataFrame` containing the requested data.

## Example
```julia
OEWS("New York City District Office")
```
"""
function OEWS(office::String)
    try
        if isnothing(oews_series[])
            oews_series[] = get_oews_series()
        end
        if isnothing(oews_data[])
            oews_data[] = get_oews_data()
        end
        return OEWS(offices[office])
    catch err
        if typeof(err) == KeyError
            nearest = findnearest(office, collect(keys(offices)), Levenshtein())[1]
            return throw(ErrorException(""""$office" is not a valid office name. Did you mean "$nearest"?"""))
        end
        throw(err)
    end
end

function LAUS(office::DistrictOffice)
    @chain laus[] begin
        @rsubset(:fips in do_counties_fips(office))
        @by(:period,
            :civilian_labor_force = sum(:civilian_labor_force),
            :employed = sum(:employed),
            :unemployed = sum(:unemployed)
        )
        @rtransform(:unemployment_rate = (:unemployed / :civilian_labor_force) * 100)
    end
end

function LAUS(office::RegionalOffice)
    @chain laus[] begin
        @rsubset(:fips in region_counties_fips(office))
        @by(:period,
            :civilian_labor_force = sum(:civilian_labor_force),
            :employed = sum(:employed),
            :unemployed = sum(:unemployed)
        )
        @rtransform(:unemployment_rate = (:unemployed / :civilian_labor_force) * 100)
    end
end

"""
    LAUS(office::String)

The `LAUS` function fetches the Local Area Unemployment Statistics (LAUS) data for the specified office, for the most recent 14-month period.

## Arguments
- `office::String`: The name of the office for which the LAUS data is requested. Can be a regional or district office.

## Returns
A `DataFrame` containing the requested data.

## Example
```julia
result = LAUS("New York City District Office")
```
"""
function LAUS(office::String)
    try
        if isnothing(laus[])
            laus[] = get_laus_data()
        end
        return LAUS(offices[office])
    catch err
        if typeof(err) == KeyError
            nearest = findnearest(office, collect(keys(offices)), Levenshtein())[1]
            return throw(ErrorException(""""$office" is not a valid office name. Did you mean "$nearest"?"""))
        end
        throw(err)
    end
end

function QCEW(office::DistrictOffice)
    @chain qcew[] begin
        @rsubset(:areacode in do_counties_fips(office))
    end
end

function QCEW(office::RegionalOffice)
    @chain qcew[] begin
        @rsubset(:areacode in region_counties_fips(office))
    end
end

"""
    QCEW(office::String)

The `QCEW` function retrieves the most recent QCEW data based on the provided office name and returns the result as a `DataFrame`.

# Arguments
- `office::String`: The name of the office for which QCEW data is requested. Can be a regional or district office.

# Returns
A `DataFrame` containing the requested data.

# Example
```julia
result = QCEW("New York City District Office")
```
"""
function QCEW(office::String)
    try
        if isnothing(qcew[])
            qcew[] = get_qcew_data()
        end
        return QCEW(offices[office])
    catch err
        if typeof(err) == KeyError
            nearest = findnearest(office, collect(keys(offices)), Levenshtein())[1]
            return throw(ErrorException(""""$office" is not a valid office name. Did you mean "$nearest"?"""))
        end
        throw(err)
    end
end

"""
    get_office_names()

Retrieve the names of regional and district offices.

# Example
```julia
office_names = get_office_names()
regional_offices = office_names.regional_offices
district_offices = office_names.district_offices
```
The code snippet retrieves the names of regional and district offices and stores them in the `office_names` variable.

# Outputs
The function returns a tuple with two elements: `regional_offices` and `district_offices`. These elements contain the names of the regional and district offices, respectively.
"""
function get_office_names()
    office_names = keys(offices)
    regional = sort(collect(filter(ofc -> occursin("Region", ofc), office_names)))
    district = sort(collect(filter(ofc -> occursin("District", ofc), office_names)))
    return (regional_offices=regional, district_offices=district)
end

"""
    do_heatmap(df::DataFrame; office_col::Symbol, data_col::Symbol, color_scheme::Symbol=:greys)

Create a district office heatmap visualization using Vega-Lite.

# Arguments
- `df`: DataFrame: The DataFrame containing the data for the heatmap.
- `office_col`: Symbol: The name of the column in `df` that contains the district office names.
- `data_col`: Symbol: The name of the column in `df` that contains the data values.
- `color_scheme` (optional): Symbol: The color scheme to use for the heatmap. Default is `:greys`. Available options are here: `https://vega.github.io/vega/docs/schemes/`

# Returns
- A Vega-Lite specification for the heatmap visualization.

# Example
```julia
heatmap = do_heatmap(df; office_col=:office_name, data_col=:value, color_scheme=:greys)
```
This code creates a heatmap visualization using the `df` DataFrame. The `office_col` argument specifies the column in `df` that contains the office names, and the `data_col` argument specifies the column that contains the data values.
"""
function do_heatmap(df::DataFrame; office_col::Symbol, data_col::Symbol, color_scheme::Symbol=:greys)
    if office_type(df[1, office_col]) == RegionalOffice
        throw(ErrorException("The first value in the $office_col column is a RegionalOffice. Did you mean to call ro_heatmap?"))
    end
    if !in(color_scheme, (
        :blues, :tealblues, :teals, :greens, :browns, :oranges, :reds, :purples, :warmgreys, :greys, :viridis, :magma, :inferno,
        :plasma, :cividis, :turbo, :bluegreen, :bluepurple, :goldgreen, :goldorange, :goldred, :greenblue, :orangered, :purplebluegreen,
        :purpleblue, :purplered, :redpurple, :yellowgreenblue, :yellowgreen, :yelloworangebrown, :yelloworangered, :darkblue,
        :darkgold, :darkgreen, :darkmulti, :darkred, :lightgreyred, :lightgreyteal, :lightmulti, :lightorange, :lighttealblue,
        :blueorange, :brownbluegreen, :purplegreen, :pinkyellowgreen, :purpleorange, :redblue, :redgrey, :redyellowblue, :redyellowgreen,
        :spectral, :rainbow, :sinebow
    ))
        throw(ErrorException("$color_scheme is not a valid color scheme. Choose an option from https://vega.github.io/vega/docs/schemes/"))
    end
    try
        @vlplot(
            width=680,
            height=400,
            mark={ 
                :geoshape,
                stroke=:black
            },
            data={
                url="https://gist.githubusercontent.com/mthelm85/f8dbc6b7683f88166725ba7bef4ee2d7/raw/31b76583cf93b20ae17784ce82be19d34dd4be62/offices_topo.json",
                format={
                    type=:topojson,
                    feature=:offices
                }
            },
            transform=[{
                lookup="properties.WH_OFFICE",
                from={
                    data=df,
                    key=office_col,
                    fields=[string(data_col)]
                }
            }],
            projection={
                type=:albersUsa
            },
            color={
                "$data_col:q",
                scale={domain=[minimum(df[!, data_col]), maximum(df[!, data_col])], scheme=color_scheme},
                legend=true
            },
            encoding={
                tooltip=[{ field=data_col }, { field="properties.WH_OFFICE", title="WHD Office" }]
            }
        )
    catch err
        throw(err)
    end
end

"""
    ro_heatmap(df::DataFrame; office_col::Symbol, data_col::Symbol, color_scheme::Symbol=:greys)

Create a regional office heatmap visualization using Vega-Lite.

# Arguments
- `df`: DataFrame: The DataFrame containing the data for the heatmap.
- `office_col`: Symbol: The name of the column in `df` that contains the regional office names.
- `data_col`: Symbol: The name of the column in `df` that contains the data values.
- `color_scheme` (optional): Symbol: The color scheme to use for the heatmap. Default is `:greys`. Available options are here: `https://vega.github.io/vega/docs/schemes/`

# Returns
- A Vega-Lite specification for the heatmap visualization.

# Example
```julia
heatmap = ro_heatmap(df; office_col=:office_name, data_col=:value, color_scheme=:greys)
```
This code creates a heatmap visualization using the `df` DataFrame. The `office_col` argument specifies the column in `df` that contains the office names, and the `data_col` argument specifies the column that contains the data values.
"""
function ro_heatmap(df::DataFrame; office_col::Symbol, data_col::Symbol, color_scheme::Symbol=:greys)
    if office_type(df[1, office_col]) == DistrictOffice
        throw(ErrorException("The first value in the $office_col column is a DistrictOffice. Did you mean to call do_heatmap?"))
    end
    if !in(color_scheme, (
        :blues, :tealblues, :teals, :greens, :browns, :oranges, :reds, :purples, :warmgreys, :greys, :viridis, :magma, :inferno,
        :plasma, :cividis, :turbo, :bluegreen, :bluepurple, :goldgreen, :goldorange, :goldred, :greenblue, :orangered, :purplebluegreen,
        :purpleblue, :purplered, :redpurple, :yellowgreenblue, :yellowgreen, :yelloworangebrown, :yelloworangered, :darkblue,
        :darkgold, :darkgreen, :darkmulti, :darkred, :lightgreyred, :lightgreyteal, :lightmulti, :lightorange, :lighttealblue,
        :blueorange, :brownbluegreen, :purplegreen, :pinkyellowgreen, :purpleorange, :redblue, :redgrey, :redyellowblue, :redyellowgreen,
        :spectral, :rainbow, :sinebow
    ))
        throw(ErrorException("$color_scheme is not a valid color scheme. Choose an option from https://vega.github.io/vega/docs/schemes/"))
    end
    try
        @vlplot(
            width=680,
            height=400,
            mark={ 
                :geoshape,
                stroke=:black
            },
            data={
                url="https://gist.githubusercontent.com/mthelm85/dfbacf9ea251965cfbf88b33e2f58222/raw/57a469e6e2ad12e4574239354315ebc5a79313e1/regions_topo.json",
                format={
                    type=:topojson,
                    feature=:regions
                }
            },
            transform=[{
                lookup="properties.WH_REGION",
                from={
                    data=df,
                    key=office_col,
                    fields=[string(data_col)]
                }
            }],
            projection={
                type=:albersUsa
            },
            color={
                "$data_col:q",
                scale={domain=[minimum(df[!, data_col]), maximum(df[!, data_col])], scheme=color_scheme},
                legend=true
            },
            encoding={
                tooltip=[{ field=data_col }, { field="properties.WH_REGION", title="WHD Region" }]
            }
        )
    catch err
        throw(err)
    end
end

"""
    get_msas()

Returns an array of sorted MSA (Metropolitan Statistical Areas) IDs.

# Example
```julia
msas = get_msas()
```

# Output
```
["29540", "35660", "21500"]
```
"""
get_msas() = sort(collect(keys(msas)))

"""
    msa_heatmap(df::DataFrame; area_col::Symbol=:area_code, data_col::Symbol=:value, color_scheme::Symbol=:greys)

Generates a heatmap plot of MSAs using Vega-Lite, including WHD District Offices that correspond to each MSA in the tooltip.

# Arguments
- `df::DataFrame`: The input DataFrame containing the data to be visualized.
- `area_col::Symbol=:area_code`: The column in the DataFrame that represents the MSAs to be plotted.
- `data_col::Symbol=:value`: The column in the DataFrame that represents the data to be used for coloring the areas.
- `color_scheme::Symbol=:greys`: The color scheme to be used for the heatmap plot.

# Example
```julia
msa_heatmap(df; color_scheme=:blues)
```

# Output
A heatmap plot where each area is colored based on the specified data column.
"""
function msa_heatmap(df::DataFrame; area_col::Symbol=:area_code, data_col::Symbol=:value, color_scheme::Symbol=:greys)
    if !in(color_scheme, (
        :blues, :tealblues, :teals, :greens, :browns, :oranges, :reds, :purples, :warmgreys, :greys, :viridis, :magma, :inferno,
        :plasma, :cividis, :turbo, :bluegreen, :bluepurple, :goldgreen, :goldorange, :goldred, :greenblue, :orangered, :purplebluegreen,
        :purpleblue, :purplered, :redpurple, :yellowgreenblue, :yellowgreen, :yelloworangebrown, :yelloworangered, :darkblue,
        :darkgold, :darkgreen, :darkmulti, :darkred, :lightgreyred, :lightgreyteal, :lightmulti, :lightorange, :lighttealblue,
        :blueorange, :brownbluegreen, :purplegreen, :pinkyellowgreen, :purpleorange, :redblue, :redgrey, :redyellowblue, :redyellowgreen,
        :spectral, :rainbow, :sinebow
    ))
        throw(ErrorException("$color_scheme is not a valid color scheme. Choose an option from https://vega.github.io/vega/docs/schemes/"))
    end
    try
        @vlplot(
            width=680,
            height=400,
            mark={ 
                :geoshape,
                stroke=:black
            },
            data={
                url="https://gist.githubusercontent.com/mthelm85/27733d4c382d5dab2406d7120c598863/raw/d490e8ad5b77a05a00c51a247dd4444a12374025/OES_WHD_topo.json",
                format={
                    type=:topojson,
                    feature=:OES_WHD_geo2
                }
            },
            transform=[{
                lookup="properties.msa7",
                from={
                    data=df,
                    key=area_col,
                    fields=[string(data_col)]
                }
            }],
            projection={
                type=:albersUsa
            },
            color={
                "$data_col:q",
                scale={domain=[minimum(df[!, data_col]), maximum(df[!, data_col])], scheme=color_scheme},
                legend=true
            },
            encoding={
                tooltip=[{ field=data_col }, { field="properties.WH_OFFICE", title="WHD Office(s)" }, { field="properties.MSA", title="MSA" }]
            }
        )
    catch err
        throw(err)
    end
end