const HEADERS = [
    "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.9999.99 Safari/537.36",
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
    "Accept-Language" => "en-US,en;q=0.9",
    "Accept-Encoding" => "gzip, deflate, br",
    "Connection" => "keep-alive",
    "Cache-Control" => "max-age=0",
]

function get_laus_data()
    println("Fetching LAUS data...")
    url = "https://www.bls.gov/web/metro/laucntycur14.txt"
    response = HTTP.get(url, HEADERS)
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
    url = "https://data.bls.gov/cew/data/files/$year/csv/$(year)_qtrly_singlefile.zip"
    
    try
        HTTP.request("HEAD", url)
    catch e
        if isa(e, HTTP.Exception) && e.status == 404
            year = year - 1
            url = "https://data.bls.gov/cew/data/files/$year/csv/$(year)_qtrly_singlefile.zip"
        else
            throw(e)
        end
    end
    
    tempdir = tempname(; cleanup=true)
    filepath = joinpath(tempdir, basename(url))
    mkdir(tempdir)
    try
        filepath = Downloads.download(url, filepath; progress=download_progress)
        println("Extracting QCEW data...")
        zarchive = ZipFile.Reader(filepath)

        for f in zarchive.files
            content = read(f)
            write(joinpath(tempdir, f.name), content)
        end

        close(zarchive)
        extracted_file = filter(file -> endswith(file, ".csv"), readdir(tempdir; join=true))

        return @chain CSV.read(extracted_file, DataFrame; normalizenames=true) begin
            @rsubset(:agglvl_code in 70:78)
            @rtransform(:area_fips = parse(Int, :area_fips))
        end
    catch err
        throw(err)
    end
end

function get_oews_series()
    println("Fetching OEWS series information...")
    url = "https://download.bls.gov/pub/time.series/oe/oe.series"
    response = HTTP.get(url, HEADERS; cookies=true)
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
    response = HTTP.get(url, HEADERS; cookies=true)
    content = String(response.body)
    df = CSV.read(IOBuffer(content), DataFrame; normalizenames=true)
    df.value = strip.(df.value)
    return df
end

function get_ces_series()
    println("Fetching CES series information...")
    url = "https://download.bls.gov/pub/time.series/sm/sm.series"
    response = HTTP.get(url, HEADERS; cookies=true)
    content = String(response.body)
    df = @chain CSV.read(IOBuffer(content), DataFrame; normalizenames=true) begin
        @rtransform(:area_code = string(:area_code))
        @rtransform(:district_office = get(msas, :area_code, missing))
        @rsubset(!ismissing(:district_office))
    end
    return df
end

function get_ces_data()
    println("Fetching CES data...")
    url = "https://download.bls.gov/pub/time.series/sm/sm.data.0.Current"
    response = HTTP.get(url, HEADERS; cookies=true)
    content = String(response.body)
    df = CSV.read(IOBuffer(content), DataFrame; normalizenames=true)
    return df
end