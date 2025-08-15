function search_core(query; max_results=10)
    api_key = Config.get_api_key(:core)
    isnothing(api_key) && throw(ArgumentError("CORE API key not configured"))
    
    url = "https://api.core.ac.uk/v3/search/works?q=$(HTTP.URIs.escapeuri(query))&limit=$max_results"
    headers = Dict("Authorization" => "Bearer $api_key")
    
    try
        response = Services.Core.api_request(:core, url; headers)
        data = JSON3.read(response)
        
        results = Dict{String, Any}[]
        if !haskey(data, "results") || isempty(data["results"])
            @warn "No results found in API response"
            return Normalize.dict_to_dataframe(Dict{String, Any}[])
        end
        
        for item in data["results"]
            authors = if haskey(item, "authors") && !isempty(item["authors"])
                try
                    [get(a, "fullName", "") for a in item["authors"]]
                catch
                    missing
                end
            else
                missing
            end
            push!(results, Dict(
                "title" => get(item, "title", missing),
                "url" => get(item, "downloadUrl", missing),
                "authors" => authors,
                "source" => "CORE",
                "id" => string(get(item, "id", missing))
            ))
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "CORE search failed" exception=(e, catch_backtrace())
        return Normalize.dict_to_dataframe(Dict{String, Any}[])
    end
end