function normalize_names!(df::DataFrame)
    for col in names(df)
        new_name = replace(replace(lowercase(strip(replace(string(col), '\n' => ""))), ' ' => '_'), "." => "")
        rename!(df, col => Symbol(new_name))
    end
end

office_type(office::String) = typeof(offices[office])
do_msas(office::DistrictOffice) = [msa.id for msa in office.msas]
do_counties_fips(office::DistrictOffice) = [county.id for county in office.counties]
region_dos_names(region::RegionalOffice) = [office.name for office in region.district_offices]
region_counties_fips(region::RegionalOffice) = reduce(vcat, [do_counties_fips(office) for office in region.district_offices])
region_msas(region::RegionalOffice) = reduce(vcat, [do_msas(office) for office in region.district_offices])