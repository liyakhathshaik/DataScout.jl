function search_wikipedia(query; max_results=10)
    url = "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$(HTTP.URIs.escapeuri(query))&format=json&srlimit=$max_results"
    
    try
        response = Core.api_request(:wikipedia, url)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        for item in data["query"]["search"]
            push!(results, Dict(
                "title" => get(item, "title", missing),
                "url" => "https://en.wikipedia.org/wiki/$(replace(item["title"], " " => "_"))",
                "authors" => missing,  # Wikipedia doesn't provide authors in search results
                "source" => "Wikipedia",
                "id" => string(get(item, "pageid", missing))
            ))
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "Wikipedia search failed" exception=e
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end