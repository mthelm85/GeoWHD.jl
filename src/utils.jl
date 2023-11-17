function normalize_names!(df::DataFrame)
    for col in names(df)
        new_name = replace(replace(lowercase(strip(replace(string(col), '\n' => ""))), ' ' => '_'), "." => "")
        rename!(df, col => Symbol(new_name))
    end
end