function get_laus_data()
    println("Fetching LAUS data...")

    # Last 14 months of LAUS data for all counties
    url = "https://www.bls.gov/web/metro/laucntycur14.txt"

    # Download the content from the URL
    response = HTTP.get(url)
    content = String(response.body)

    # Skip to the 7th line
    lines = split(content, '\n')[7:end-6]

    # Join the lines back into a single string
    data_section = join(lines, '\n')

    # Create a CSV.Reader from the data section with pipe delimiter
    reader = CSV.File(IOBuffer(data_section), delim='|', header=false, groupmark=',')

    df = DataFrame(reader)
    rename!(df, [:area_code, :state_fips, :county_fips, :area_title, :period, :civilian_labor_force, :employed, :unemployed, :unemployment_rate])
    df.fips = parse.(Int, lpad.(df.state_fips, 2, "0") .* lpad.(df.county_fips, 3, "0"))
    df.period = lastdayofmonth.(Date.(strip.(replace.(df.period, "(p)" => "")), dateformat"u-yy") .+ Year(2000))
    return df
end