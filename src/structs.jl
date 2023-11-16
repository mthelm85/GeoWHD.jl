struct County
    name::String
    county_fips::Int
    state::String
    state_fips::Int
    # geo::Dict
    id::Int
    district_office_name::String
    # district_office_id::Int
end

struct DistrictOffice
    name::String
    # id::Int
    counties::Vector{County}
    region_name::String
    # region_id::Int
    # geo::Dict
end

struct RegionalOffice
    name::String
    # id::Int
    district_offices::Vector{DistrictOffice}
    # geo::Dict
end

do_counties_fips(office::DistrictOffice) = [county.id for county in office.counties]
region_dos_names(region::RegionalOffice) = [office.name for office in region.district_offices]
region_counties_fips(region::RegionalOffice) = reduce(vcat, [do_counties_fips(office) for office in region.district_offices])

counties = CSV.read(project_path("data/do-counties.csv"), DataFrame)

whd_counties = [County(
    row.county_name,
    parse(Int, last(string(row.GEOID10), 3)),
    row.state_id,
    parse(Int, first(lpad(row.GEOID10, 2, "0"), 2)),
    row.GEOID10,
    row.wh_office_name
) for row in eachrow(counties)]

district_offices = Dict(office => DistrictOffice(
    office,
    filter(county -> county.district_office_name == office, whd_counties),
    filter(row -> row.wh_office_name == office, counties)[1, :region_name]
) for office in unique(counties.wh_office_name))

regional_offices = Dict(region => RegionalOffice(
    region,
    [v for (k,v) in district_offices if v.region_name == region]
) for region in unique(counties.region_name))