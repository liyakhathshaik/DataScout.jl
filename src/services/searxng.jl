function search_searxng(query; instance="https://searx.space", max_results=10)
    # Allow custom instance
    instance_url = if haskey(ENV, "SEARXNG_INSTANCE")
        ENV["SEARXNG_INSTANCE"]
    else
        instance
    end
    url = "$instance_url/search?q=$(HTTP.URIs.escapeuri(query))&format=json"
    
    try
        response = Core.api_request(:searxng, url)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        count = 0
        for result in data["results"]
            count >= max_results && break
            push!(results, Dict(
                "title" => get(result, "title", missing),
                "url" => get(result, "url", missing),
                "authors" => missing,
                "source" => "SearxNG",
                "id" => missing
            ))
            count += 1
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "SearxNG search failed" exception=e
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end