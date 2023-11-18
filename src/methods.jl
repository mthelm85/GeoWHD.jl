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
- `color_scheme` (optional): Symbol: The color scheme to use for the heatmap. Default is `:greys`.

# Returns
- A Vega-Lite specification for the heatmap visualization.

# Example
```julia
heatmap = do_heatmap(df; office_col=:office_name, data_col=:value, color_scheme=:greys)
```
This code creates a heatmap visualization using the `df` DataFrame. The `office_col` argument specifies the column in `df` that contains the office names, and the `data_col` argument specifies the column that contains the data values.
"""
function do_heatmap(df::DataFrame; office_col::Symbol, data_col::Symbol, color_scheme::Symbol=:greys)
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
end

"""
    ro_heatmap(df::DataFrame; office_col::Symbol, data_col::Symbol, color_scheme::Symbol=:greys)

Create a regional office heatmap visualization using Vega-Lite.

# Arguments
- `df`: DataFrame: The DataFrame containing the data for the heatmap.
- `office_col`: Symbol: The name of the column in `df` that contains the regional office names.
- `data_col`: Symbol: The name of the column in `df` that contains the data values.
- `color_scheme` (optional): Symbol: The color scheme to use for the heatmap. Default is `:greys`.

# Returns
- A Vega-Lite specification for the heatmap visualization.

# Example
```julia
heatmap = ro_heatmap(df; office_col=:office_name, data_col=:value, color_scheme=:greys)
```
This code creates a heatmap visualization using the `df` DataFrame. The `office_col` argument specifies the column in `df` that contains the office names, and the `data_col` argument specifies the column that contains the data values.
"""
function ro_heatmap(df::DataFrame; office_col::Symbol, data_col::Symbol, color_scheme::Symbol=:greys)
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
end