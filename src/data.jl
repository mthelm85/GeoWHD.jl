function get_laus_data()
    println("Fetching LAUS data...")
    url = "https://www.bls.gov/web/metro/laucntycur14.txt"
    response = HTTP.get(url)
    content = String(response.body)
    # Skip to the 7th line
    lines = split(content, '\n')[7:end-6]
    # Join the lines back into a single string
    data_section = join(lines, '\n')
    reader = CSV.File(IOBuffer(data_section), delim='|', header=false, groupmark=',')
    df = DataFrame(reader)
    rename!(df, [:area_code, :state_fips, :county_fips, :area_title, :period, :civilian_labor_force, :employed, :unemployed, :unemployment_rate])
    df.fips = parse.(Int, lpad.(df.state_fips, 2, "0") .* lpad.(df.county_fips, 3, "0"))
    df.period = lastdayofmonth.(Date.(strip.(replace.(df.period, "(p)" => "")), dateformat"u-yy") .+ Year(2000))
    return df
end

function get_qcew_data()
    println("Fetching QCEW data...")
    year = Dates.year(now())
    url = "https://data.bls.gov/cew/data/files/$year/xls/$(year)_all_county_high_level.zip"
    res = HTTP.request("HEAD", url)
    if res.status !== 200
        year = year - 1
    end
    tempdir = tempname(; cleanup=true)
    filepath = joinpath(tempdir, basename(url))
    mkdir(tempdir)
    try
        filepath = Downloads.download(url, filepath)
        println("Extracting QCEW data...")
        zarchive = ZipFile.Reader(filepath)

        for f in zarchive.files
            write(joinpath(tempdir, f.name), read(f))
        end

        extracted_files = filter(file -> endswith(file, ".xlsx"), readdir(tempdir; join=true))
        xf = XLSX.readxlsx(extracted_files[1])
        us = DataFrame(XLSX.readtable(extracted_files[1], XLSX.sheetnames(xf)[1]; infer_eltypes=true))
        pr = DataFrame(XLSX.readtable(extracted_files[1], XLSX.sheetnames(xf)[2]; infer_eltypes=true))
        df = vcat(us, pr)
        normalize_names!(df)
        return @chain df begin
            @rsubset(:area_type == "County")
            @transform(:areacode = parse.(Int, :areacode))
        end
    catch err
        throw(err)
    end
end

function get_oews_series()
    println("Fetching OEWS series information...")
    url = "https://download.bls.gov/pub/time.series/oe/oe.series"
    response = HTTP.get(url)
    content = String(response.body)
    df = @chain CSV.read(IOBuffer(content), DataFrame; normalizenames=true) begin
        @rsubset(:areatype_code == "M")
        @rtransform(:area_code = string(:area_code))
        @rtransform(:district_office = msas[:area_code])
    end
    return df
end

function get_oews_data()
    println("Fetching OEWS data...")
    url = "https://download.bls.gov/pub/time.series/oe/oe.data.0.Current"
    response = HTTP.get(url)
    content = String(response.body)
    df = CSV.read(IOBuffer(content), DataFrame; normalizenames=true)
    df.value = strip.(df.value)
    return df
end