struct County
    name::String
    county_fips::Int
    state::String
    state_fips::Int
    id::Int
    district_office_name::String
end

struct MSA
    id::String
    district_offices::Vector{String}
end

struct DistrictOffice
    name::String
    counties::Vector{County}
    msas::Vector{MSA}
    region_name::String
end

struct RegionalOffice
    name::String
    district_offices::Vector{DistrictOffice}
end

counties = CSV.read(project_path("data/do-counties.csv"), DataFrame)
msas = JSON.parsefile(project_path("data/do-msa.json"); dicttype=Dict{String, Vector{String}})

whd_counties = [County(
    row.county_name,
    parse(Int, last(string(row.GEOID10), 3)),
    row.state_id,
    parse(Int, first(lpad(row.GEOID10, 2, "0"), 2)),
    row.GEOID10,
    row.wh_office_name
) for row in eachrow(counties)]

whd_msas = [MSA(k,v) for (k,v) in msas]

district_offices = Dict(office => DistrictOffice(
    office,
    filter(county -> county.district_office_name == office, whd_counties),
    filter(msa -> office in msa.district_offices, whd_msas),
    filter(row -> row.wh_office_name == office, counties)[1, :region_name]
) for office in unique(counties.wh_office_name))

regional_offices = Dict(region => RegionalOffice(
    region,
    [v for (k,v) in district_offices if v.region_name == region]
) for region in unique(counties.region_name))