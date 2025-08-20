function search_openlibrary(query; max_results=10)
    url = "https://openlibrary.org/search.json?q=$(HTTP.URIs.escapeuri(query))&limit=$max_results"
    
    try
        response = Core.api_request(:openlibrary, url)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        for doc in data["docs"]
            authors = if haskey(doc, "author_name")
                doc["author_name"]
            else
                missing
            end
            push!(results, Dict(
                "title" => get(doc, "title", missing),
                "url" => "https://openlibrary.org/works/$(get(doc, "key", ""))",
                "authors" => authors,
                "source" => "Open Library",
                "id" => get(doc, "key", missing)
            ))
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "Open Library search failed" exception=e
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end