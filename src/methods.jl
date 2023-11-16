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