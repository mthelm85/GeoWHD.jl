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
A `DataFrame` of the following form:

```
14×5 DataFrame
 Row │ period      civilian_labor_force  employed  unemployed  unemployment_rate
     │ Date        Int64                 Int64     Int64       Float64
─────┼───────────────────────────────────────────────────────────────────────────
   1 │ 2022-08-31               4056378   3933799      122579            3.02188
   2 │ 2022-09-30               4081715   3971844      109871            2.69179
   3 │ 2022-10-31               4071122   3959961      111161            2.73048
   4 │ 2022-11-30               4047187   3939729      107458            2.65513
   5 │ 2022-12-31               4053928   3960111       93817            2.31422
   6 │ 2023-01-31               4055028   3947670      107358            2.64753
   7 │ 2023-02-28               4089691   3982743      106948            2.61506
   8 │ 2023-03-31               4121556   4012693      108863            2.64131
   9 │ 2023-04-30               4120197   4022722       97475            2.36578
  10 │ 2023-05-31               4134965   4021108      113857            2.75352
  11 │ 2023-06-30               4190977   4061582      129395            3.08747
  12 │ 2023-07-31               4206597   4071974      134623            3.20028
  13 │ 2023-08-31               4231115   4094061      137054            3.23919
  14 │ 2023-09-30               4242665   4109053      133612            3.14925
```

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
            return throw(ErrorException("$office is not a valid office name. Did you mean $nearest?"))
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