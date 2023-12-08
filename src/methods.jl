function CES(office::DistrictOffice)
    msas = do_msas(office)
    series = @chain ces_series[] begin
        @rsubset(:area_code in msas)
    end
    return leftjoin(series, ces_data[]; on=:series_id, makeunique=true)
end

function CES(office::RegionalOffice)
    msas = region_msas(office)
    series = @chain ces_series[] begin
        @rsubset(:area_code in msas)
    end
    return leftjoin(series, ces_data[]; on=:series_id, makeunique=true)
end

"""
    CES(office::String)

Retrieve the most recent CES (Current Employment Statistics) data for a specific office.

## Arguments
- `office::String`: The name of the office for which CES data is requested. Can be a regional or district office.

## Returns
A `DataFrame` containing the requested data.

## Example
```julia
CES("New York City District Office")
```
"""
function CES(office::String)
    try
        office_lookup = offices[office]
        if isnothing(ces_series[])
            ces_series[] = get_ces_series()
        end
        if isnothing(ces_data[])
            ces_data[] = get_ces_data()
        end
        return CES(office_lookup)
    catch err
        if typeof(err) == KeyError
            nearest = findnearest(office, collect(keys(offices)), Levenshtein())[1]
            return throw(ErrorException(""""$office" is not a valid office name. Did you mean "$nearest"?"""))
        end
        throw(err)
    end
end

function OEWS(office::DistrictOffice)
    msas = do_msas(office)
    series = @chain oews_series[] begin
        @rsubset(:area_code in msas)
    end
    return leftjoin(series, oews_data[]; on=:series_id, makeunique=true)
end

function OEWS(office::RegionalOffice)
    msas = region_msas(office)
    series = @chain oews_series[] begin
        @rsubset(:area_code in msas)
    end
    return leftjoin(series, oews_data[]; on=:series_id, makeunique=true)
end

"""
    OEWS(occupation_code::Int)

Retrieve the most recent OEWS (Occupational Employment and Wage Statistics) data for a specific occupation.

## Arguments
- `occupation_code::Int`: The occupation code for which OEWS data is requested. Options available here: https://download.bls.gov/pub/time.series/oe/oe.occupation

## Returns
A `DataFrame` containing the requested data.

## Example
```julia
OEWS(352011)
```
"""
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
        office_lookup = offices[office]
        if isnothing(oews_series[])
            oews_series[] = get_oews_series()
        end
        if isnothing(oews_data[])
            oews_data[] = get_oews_data()
        end
        return OEWS(office_lookup)
    catch err
        if typeof(err) == KeyError
            nearest = findnearest(office, collect(keys(offices)), Levenshtein())[1]
            return throw(ErrorException(""""$office" is not a valid office name. Did you mean "$nearest"?"""))
        end
        throw(err)
    end
end

function LAUS(office::DistrictOffice; aggregate::Bool=true)
    fips = do_counties_fips(office)
    
    if aggregate
        return @chain laus[] begin
            @rsubset(:fips in fips)
            @by(:period,
                :civilian_labor_force = sum(:civilian_labor_force),
                :employed = sum(:employed),
                :unemployed = sum(:unemployed)
            )
            @rtransform(:unemployment_rate = (:unemployed / :civilian_labor_force) * 100)
        end
    else
        return @chain laus[] begin
            @rsubset(:fips in fips)
            @rtransform(:unemployment_rate = (:unemployed / :civilian_labor_force) * 100)
        end
    end
end

function LAUS(office::RegionalOffice; aggregate::Bool=true)
    fips = region_counties_fips(office)

    if aggregate
        return @chain laus[] begin
            @rsubset(:fips in fips)
            @by(:period,
                :civilian_labor_force = sum(:civilian_labor_force),
                :employed = sum(:employed),
                :unemployed = sum(:unemployed)
            )
            @rtransform(:unemployment_rate = (:unemployed / :civilian_labor_force) * 100)
        end
    else
        return @chain laus[] begin
            @rsubset(:fips in fips)
            @rtransform(:unemployment_rate = (:unemployed / :civilian_labor_force) * 100)
        end
    end
end

"""
    LAUS(; aggregate::Bool=false)

The `LAUS` function fetches the Local Area Unemployment Statistics (LAUS) data for the most recent 14-month period.

## Arguments
- `aggregate::Bool`: A boolean that determines if you want the data aggregated, as opposed to receiving the county-level data.

## Returns
A `DataFrame` containing the requested data.

## Example
```julia
result = LAUS()
```
"""
function LAUS(; aggregate::Bool=false)
    if aggregate
        return @chain laus[] begin
            @by(:period,
                :civilian_labor_force = sum(:civilian_labor_force),
                :employed = sum(:employed),
                :unemployed = sum(:unemployed)
            )
            @rtransform(:unemployment_rate = (:unemployed / :civilian_labor_force) * 100)
        end
    else
        return @chain laus[] begin
            @rtransform(:unemployment_rate = (:unemployed / :civilian_labor_force) * 100)
        end
    end
end

"""
    LAUS(office::String; aggregate::Bool=true)

The `LAUS` function fetches the Local Area Unemployment Statistics (LAUS) data for the specified office, for the most recent 14-month period.

## Arguments
- `office::String`: The name of the office for which the LAUS data is requested. Can be a regional or district office.
- `aggregate::Bool`: A boolean that determines if you want the data aggregated, as opposed to receiving the county-level data.

## Returns
A `DataFrame` containing the requested data.

## Example
```julia
result = LAUS("New York City District Office")
```
"""
function LAUS(office::String; aggregate::Bool=true)
    try
        office_lookup = offices[office]
        if isnothing(laus[])
            laus[] = get_laus_data()
        end
        return LAUS(office_lookup; aggregate)
    catch err
        if typeof(err) == KeyError
            nearest = findnearest(office, collect(keys(offices)), Levenshtein())[1]
            return throw(ErrorException(""""$office" is not a valid office name. Did you mean "$nearest"?"""))
        end
        throw(err)
    end
end

function QCEW(office::DistrictOffice)
    fips = do_counties_fips(office)
    @chain qcew[] begin
        @rsubset(:area_fips in fips)
    end
end

function QCEW(office::RegionalOffice)
    fips = region_counties_fips(office)
    @chain qcew[] begin
        @rsubset(:area_fips in fips)
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
        office_lookup = offices[office]
        if isnothing(qcew[])
            qcew[] = get_qcew_data()
        end
        return QCEW(office_lookup)
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
- `color_scheme` (optional): Symbol: The color scheme to use for the heatmap. Default is `:greys`. Available options are here: https://vega.github.io/vega/docs/schemes/

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
            width = 680,
            height = 400,
            config={mark={invalid=NaN}},
            mark = {
                :geoshape,
                stroke = :black
            },
            data = {
                values = JSON.json(JSON.parsefile(project_path("data/offices_topo.json"))),
                format = {
                    type = :topojson,
                    feature = :offices
                }
            },
            transform = [{
                default=NaN,
                lookup = "properties.WH_OFFICE",
                from = {
                    data = df,
                    key = office_col,
                    fields = [string(data_col)]
                }
            }],
            projection = {
                type = :albersUsa
            },
            color = {
                "$data_col:q",
                scale = {domain = [minimum(df[!, data_col]), maximum(df[!, data_col])], scheme = color_scheme},
                legend = true,
                condition={test="datum['value'] === null", value="transparent"},
            },
            encoding = {
                tooltip = [{field = data_col}, {field = "properties.WH_OFFICE", title = "WHD Office"}]
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
- `color_scheme` (optional): Symbol: The color scheme to use for the heatmap. Default is `:greys`. Available options are here: https://vega.github.io/vega/docs/schemes/

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
            width = 680,
            height = 400,
            config={mark={invalid=NaN}},
            mark = {
                :geoshape,
                stroke = :black
            },
            data = {
                values = JSON.json(JSON.parsefile(project_path("data/regions_topo.json"))),
                format = {
                    type = :topojson,
                    feature = :regions
                }
            },
            transform = [{
                default=NaN,
                lookup = "properties.WH_REGION",
                from = {
                    data = df,
                    key = office_col,
                    fields = [string(data_col)]
                }
            }],
            projection = {
                type = :albersUsa
            },
            color = {
                "$data_col:q",
                scale = {domain = [minimum(df[!, data_col]), maximum(df[!, data_col])], scheme = color_scheme},
                legend = true,
                condition={test="datum['value'] === null", value="transparent"},
            },
            encoding = {
                tooltip = [{field = data_col}, {field = "properties.WH_REGION", title = "WHD Region"}]
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
- `color_scheme::Symbol=:greys`: The color scheme to use for the heatmap. Default is `:greys`. Available options are here: https://vega.github.io/vega/docs/schemes/

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
            width = 680,
            height = 400,
            config={mark={invalid=NaN}},
            mark = {
                :geoshape,
                stroke = :black
            },
            data = {
                values = JSON.json(JSON.parsefile(project_path("data/OES_WHD_topo.json"))),
                format = {
                    type = :topojson,
                    feature = :OES_WHD_geo2
                }
            },
            transform = [{
                default=NaN,
                lookup = "properties.msa7",
                from = {
                    data = df,
                    key = area_col,
                    fields = [string(data_col)]
                }
            }],
            projection = {
                type = :albersUsa
            },
            color = {
                "$data_col:q",
                scale = {domain = [minimum(df[!, data_col]), maximum(df[!, data_col])], scheme = color_scheme},
                legend = true,
                condition={test="datum['value'] === null", value="transparent"},
            },
            encoding = {
                tooltip = [{field = data_col}, {field = "properties.WH_OFFICE", title = "WHD Office(s)"}, {field = "properties.MSA", title = "MSA"}]
            }
        )
    catch err
        throw(err)
    end
end

"""
    do_msa_heatmap(df::DataFrame, office::String; area_col::Symbol=:area_code, data_col::Symbol=:value, color_scheme::Symbol=:greys)

Generates a heatmap plot of MSAs for a specific District Office using Vega-Lite.

# Arguments
- `df::DataFrame`: The input DataFrame containing the data to be visualized.
- `office::String`: The District Office for which you would like to create the visual.
- `area_col::Symbol=:area_code`: The column in the DataFrame that represents the MSAs to be plotted.
- `data_col::Symbol=:value`: The column in the DataFrame that represents the data to be used for coloring the areas.
- `color_scheme::Symbol=:greys`: The color scheme to use for the heatmap. Default is `:greys`. Available options are here: https://vega.github.io/vega/docs/schemes/

# Example
```julia
do_msa_heatmap(df; color_scheme=:blues)
```

# Output
A heatmap plot where each area is colored based on the specified data column.
"""
function do_msa_heatmap(df::DataFrame, office::String; area_col::Symbol=:area_code, data_col::Symbol=:value, color_scheme::Symbol=:greys)
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
        offices[office]
    catch err
        if typeof(err) == KeyError
            nearest = findnearest(office, collect(keys(offices)), Levenshtein())[1]
            return throw(ErrorException(""""$office" is not a valid office name. Did you mean "$nearest"?"""))
        end
        throw(err)
    end
    if office_type(office) == RegionalOffice
        throw(ErrorException("$office is a RegionalOffice. Did you mean to call ro_msa_heatmap?"))
    end
    try
        oes = JSON.parsefile(project_path("data/OES_WHD_DO.json"))
        filtered_dict = Dict(
            "arcs" => oes["arcs"],
            "objects" => Dict("OES_WHD" => Dict(
                "type" => "GeometryCollection",
                "geometries" => filter(dict -> office in dict["properties"]["WH_OFFICE"], oes["objects"]["OES_WHD"]["geometries"])
            )),
            "type" => oes["type"],
            "transform" => oes["transform"]
        )

        @vlplot(
            width = 680,
            height = 400,
            config={mark={invalid=NaN}},
            mark = {
                :geoshape,
                stroke = :black
            },
            data = {
                values = JSON.json(filtered_dict),
                format = {
                    type = :topojson,
                    feature = :OES_WHD
                }
            },
            transform = [{
                default=NaN,
                lookup = "properties.msa7",
                from = {
                    data = df,
                    key = area_col,
                    fields = [string(data_col)]
                }
            }],
            projection = {
                type = :mercator
            },
            color = {
                "$data_col:q",
                scale = {domain = [minimum(df[!, data_col]), maximum(df[!, data_col])], scheme = color_scheme},
                legend = true,
                condition={test="datum['value'] === null", value="transparent"},
            },
            encoding = {
                tooltip = [{field = data_col}, {field = "properties.MSA", title = "MSA"}]
            }
        )
    catch err
        throw(err)
    end
end

"""
    do_county_heatmap(df::DataFrame, office::String; fips_col::Symbol=:fips, data_col::Symbol, color_scheme::Symbol=:greys)

Generates a heatmap plot of counties for a specific District Office using Vega-Lite.

# Arguments
- `df::DataFrame`: The input DataFrame containing the data to be visualized.
- `office::String`: The District Office for which you would like to create the visual.
- `fips_col::Symbol=:fips`: The column in the DataFrame that represents the 5-digit county FIPS to be plotted.
- `data_col::Symbol`: The column in the DataFrame that represents the data to be used for coloring the areas.
- `color_scheme::Symbol=:greys`: The color scheme to use for the heatmap. Default is `:greys`. Available options are here: https://vega.github.io/vega/docs/schemes/

# Example
```julia
do_county_heatmap(df; color_scheme=:blues)
```

# Output
A heatmap plot where each area is colored based on the specified data column.
"""
function do_county_heatmap(df::DataFrame, office::String; fips_col::Symbol=:fips, data_col::Symbol, color_scheme::Symbol=:greys)
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
        offices[office]
    catch err
        if typeof(err) == KeyError
            nearest = findnearest(office, collect(keys(offices)), Levenshtein())[1]
            return throw(ErrorException(""""$office" is not a valid office name. Did you mean "$nearest"?"""))
        end
        throw(err)
    end
    if office_type(office) == RegionalOffice
        throw(ErrorException("$office is a RegionalOffice. Did you mean to call ro_county_heatmap?"))
    end
    try
        laus = JSON.parsefile(project_path("data/counties_topo.json"))

        filtered_dict = Dict(
            "arcs" => laus["arcs"],
            "objects" => Dict("counties" => Dict(
                "type" => "GeometryCollection",
                "geometries" => filter(dict -> office == dict["properties"]["WH_OFFICE"], laus["objects"]["counties"]["geometries"])
            )),
            "type" => laus["type"],
            "transform" => laus["transform"]
        )

        df[!, fips_col] = lpad.(df[!, fips_col], 5, "0")

        @vlplot(
            width = 680,
            height = 400,
            config={mark={invalid=NaN}},
            mark = {
                :geoshape,
                stroke = :black
            },
            data = {
                values = JSON.json(filtered_dict),
                format = {
                    type = :topojson,
                    feature = :counties
                }
            },
            transform = [{
                default=NaN,
                lookup = "properties.FIPS",
                from = {
                    data = df,
                    key = fips_col,
                    fields = [string(data_col)]
                }
            }],
            projection = {
                type = office == "Seattle District Office" ? :albersUsa : :mercator
            },
            color = {
                "$data_col:q",
                scale = {domain = [minimum(df[!, data_col]), maximum(df[!, data_col])], scheme = color_scheme},
                legend = true,
                condition={test="datum['value'] === null", value="transparent"},
            },
            encoding = {
                tooltip = [{field = data_col}, {field = "properties.COUNTYNAME", title = "County"}]
            }
        )
    catch err
        throw(err)
    end
end

"""
    county_heatmap(df::DataFrame; fips_col::Symbol=:fips, data_col::Symbol, color_scheme::Symbol=:greys)

Generates a heatmap plot of counties using Vega-Lite, including WHD District/Regional Offices that correspond to each county in the tooltip.

# Arguments
- `df::DataFrame`: The input DataFrame containing the data to be visualized.
- `fips_col::Symbol=:fips`: The column in the DataFrame that represents the 5-digit FIPS for each county to be plotted.
- `data_col::Symbol`: The column in the DataFrame that represents the data to be used for coloring the areas.
- `color_scheme::Symbol=:greys`: The color scheme to use for the heatmap. Default is `:greys`. Available options are here: https://vega.github.io/vega/docs/schemes/

# Example
```julia
county_heatmap(df; color_scheme=:blues)
```

# Output
A heatmap plot where each area is colored based on the specified data column.
"""
function county_heatmap(df::DataFrame; fips_col::Symbol=:fips, data_col::Symbol, color_scheme::Symbol=:greys)
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
        df[!, fips_col] = lpad.(df[!, fips_col], 5, "0")

        @vlplot(
            width = 680,
            height = 400,
            config={mark={invalid=NaN}},
            mark = {
                :geoshape,
                stroke = :black
            },
            data = {
                values = JSON.json(JSON.parsefile(project_path("data/counties_topo.json"))),
                format = {
                    type = :topojson,
                    feature = :counties
                }
            },
            transform = [{
                default=NaN,
                lookup = "properties.FIPS",
                from = {
                    data = df,
                    key = fips_col,
                    fields = [string(data_col)]
                }
            }],
            projection = {
                type = :albersUsa
            },
            color = {
                "$data_col:q",
                scale = {domain = [minimum(df[!, data_col]), maximum(df[!, data_col])], scheme = color_scheme},
                legend = true,
                condition={test="datum['value'] === null", value="transparent"},
            },
            encoding = {
                tooltip = [{field = data_col}, {field = "properties.WH_OFFICE", title = "WHD Office"}, {field = "properties.WH_REGION", title = "WHD Region"}]
            }
        )
    catch err
        throw(err)
    end
end

"""
    ro_msa_heatmap(df::DataFrame, office::String; area_col::Symbol=:area_code, data_col::Symbol, color_scheme::Symbol=:greys)

Generates a heatmap plot of MSAs for a specific Regional Office using Vega-Lite.

# Arguments
- `df::DataFrame`: The input DataFrame containing the data to be visualized.
- `office::String`: The Regional Office for which you would like to create the visual.
- `area_col::Symbol=:area_code`: The column in the DataFrame that represents the MSAs to be plotted.
- `data_col::Symbol`: The column in the DataFrame that represents the data to be used for coloring the areas.
- `color_scheme::Symbol=:greys`: The color scheme to use for the heatmap. Default is `:greys`. Available options are here: https://vega.github.io/vega/docs/schemes/

# Example
```julia
ro_msa_heatmap(df; data_col=:unemployment_rate, color_scheme=:blues)
```

# Output
A heatmap plot where each area is colored based on the specified data column.
"""
function ro_msa_heatmap(df::DataFrame, office::String; area_col::Symbol=:area_code, data_col::Symbol, color_scheme::Symbol=:greys)
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
        offices[office]
    catch err
        if typeof(err) == KeyError
            nearest = findnearest(office, collect(keys(offices)), Levenshtein())[1]
            return throw(ErrorException(""""$office" is not a valid office name. Did you mean "$nearest"?"""))
        end
        throw(err)
    end
    if office_type(office) == DistrictOffice
        throw(ErrorException("$office is a DistrictOffice. Did you mean to call do_msa_heatmap?"))
    end
    try
        oes = JSON.parsefile(project_path("data/OES_WHD_RO.json"))
        filtered_dict = Dict(
            "arcs" => oes["arcs"],
            "objects" => Dict("OES_WHD" => Dict(
                "type" => "GeometryCollection",
                "geometries" => filter(dict -> office in dict["properties"]["WH_REGION"], oes["objects"]["OES_WHD"]["geometries"])
            )),
            "type" => oes["type"],
            "transform" => oes["transform"]
        )

        @vlplot(
            width = 680,
            height = 400,
            config={mark={invalid=NaN}},
            mark = {
                :geoshape,
                stroke = :black
            },
            data = {
                values = JSON.json(filtered_dict),
                format = {
                    type = :topojson,
                    feature = :OES_WHD
                }
            },
            transform = [{
                default=NaN,
                lookup = "properties.msa7",
                from = {
                    data = df,
                    key = area_col,
                    fields = [string(data_col)]
                }
            }],
            projection = {
                type = office == "Western Region" ? :albersUsa : :mercator
            },
            color = {
                "$data_col:q",
                scale = {domain = [minimum(df[!, data_col]), maximum(df[!, data_col])], scheme = color_scheme},
                legend = true,
                condition={test="datum['value'] === null", value="transparent"},
            },
            encoding = {
                tooltip = [{field = data_col}, {field = "properties.MSA", title = "MSA"}]
            }
        )
    catch err
        throw(err)
    end
end

"""
    ro_county_heatmap(df::DataFrame, office::String; fips_col::Symbol=:fips, data_col::Symbol, color_scheme::Symbol=:greys)

Generates a heatmap plot of counties for a specific Regional Office using Vega-Lite.

# Arguments
- `df::DataFrame`: The input DataFrame containing the data to be visualized.
- `office::String`: The Regional Office for which you would like to create the visual.
- `fips_col::Symbol=:fips`: The column in the DataFrame that represents the 5-digit county FIPS to be plotted.
- `data_col::Symbol`: The column in the DataFrame that represents the data to be used for coloring the areas.
- `color_scheme::Symbol=:greys`: The color scheme to use for the heatmap. Default is `:greys`. Available options are here: https://vega.github.io/vega/docs/schemes/

# Example
```julia
ro_county_heatmap(df; data_col=:unemployment_rate, color_scheme=:blues)
```

# Output
A heatmap plot where each area is colored based on the specified data column.
"""
function ro_county_heatmap(df::DataFrame, office::String; fips_col::Symbol=:fips, data_col::Symbol, color_scheme::Symbol=:greys)
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
        offices[office]
    catch err
        if typeof(err) == KeyError
            nearest = findnearest(office, collect(keys(offices)), Levenshtein())[1]
            return throw(ErrorException(""""$office" is not a valid office name. Did you mean "$nearest"?"""))
        end
        throw(err)
    end
    if office_type(office) == DistrictOffice
        throw(ErrorException("$office is a DistrictOffice. Did you mean to call do_county_heatmap?"))
    end
    try
        laus = JSON.parsefile(project_path("data/counties_topo.json"))

        filtered_dict = Dict(
            "arcs" => laus["arcs"],
            "objects" => Dict("counties" => Dict(
                "type" => "GeometryCollection",
                "geometries" => filter(dict -> office == dict["properties"]["WH_REGION"], laus["objects"]["counties"]["geometries"])
            )),
            "type" => laus["type"],
            "transform" => laus["transform"]
        )

        df[!, fips_col] = lpad.(df[!, fips_col], 5, "0")

        @vlplot(
            width = 680,
            height = 400,
            config={mark={invalid=NaN}},
            mark = {
                :geoshape,
                stroke = :black
            },
            data = {
                values = JSON.json(filtered_dict),
                format = {
                    type = :topojson,
                    feature = :counties
                }
            },
            transform = [{
                default=NaN,
                lookup = "properties.FIPS",
                from = {
                    data = df,
                    key = fips_col,
                    fields = [string(data_col)]
                }
            }],
            projection = {
                type = (office == "Seattle District Office" || office == "Western Region") ? :albersUsa : :mercator
            },
            color = {
                "$data_col:q",
                scale = {domain = [minimum(df[!, data_col]), maximum(df[!, data_col])], scheme = color_scheme},
                legend = true,
                condition={test="datum['value'] === null", value="transparent"},
            },
            encoding = {
                tooltip = [{field = data_col}, {field = "properties.COUNTYNAME", title = "County"}]
            }
        )
    catch err
        throw(err)
    end
end