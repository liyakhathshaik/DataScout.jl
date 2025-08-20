function search_internetarchive(query; max_results=10)
    url = "https://archive.org/advancedsearch.php?q=$(HTTP.URIs.escapeuri(query))&output=json&rows=$max_results"
    
    try
        response = Core.api_request(:internetarchive, url)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        for doc in data["response"]["docs"]
            authors = if haskey(doc, "creator")
                isa(doc["creator"], String) ? [doc["creator"]] : doc["creator"]
            else
                missing
            end
            push!(results, Dict(
                "title" => get(doc, "title", missing),
                "url" => "https://archive.org/details/$(doc["identifier"])",
                "authors" => authors,
                "source" => "Internet Archive",
                "id" => get(doc, "identifier", missing)
            ))
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "Internet Archive search failed" exception=e
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end