function search_figshare(query; max_results=10)
    url = "https://api.figshare.com/v2/articles?search=$(HTTP.URIs.escapeuri(query))&page_size=$max_results"
    
    try
        response = Core.api_request(:figshare, url)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        for item in data
            authors = isempty(item["authors"]) ? missing : [a["full_name"] for a in item["authors"]]
            push!(results, Dict(
                "title" => get(item, "title", missing),
                "url" => get(item, "url", missing),
                "authors" => authors,
                "source" => "Figshare",
                "id" => string(get(item, "id", missing))
            ))
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "Figshare search failed" exception=e
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end