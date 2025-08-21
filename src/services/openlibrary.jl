function search_openlibrary(query; max_results=10)
    url = "https://openlibrary.org/search.json?q=$(HTTP.URIs.escapeuri(query))&limit=$max_results"
    
    try
        response = Core.api_request(:openlibrary, url)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        for doc in get(data, "docs", Any[])
            authors = if haskey(doc, "author_name")
                # Normalize to Vector{String}
                try
                    collect(String, doc["author_name"])
                catch
                    missing
                end
            else
                missing
            end
            push!(results, Dict(
                "title" => get(doc, "title", missing),
                "url" => begin
                    work_key = get(doc, "key", "")
                    isempty(String(work_key)) ? missing : "https://openlibrary.org/works/$(work_key)"
                end,
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