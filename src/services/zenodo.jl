function search_zenodo(query; max_results=10)
    url = "https://zenodo.org/api/records?q=$(HTTP.URIs.escapeuri(query))&size=$max_results"
    
    try
        response = Core.api_request(:zenodo, url)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        for item in data["hits"]["hits"]
            authors = if haskey(item["metadata"], "creators")
                [get(c, "name", missing) for c in item["metadata"]["creators"]]
            else
                missing
            end
            push!(results, Dict(
                "title" => get(item["metadata"], "title", missing),
                "url" => begin
                    # Prefer DOI if present and non-empty, fall back to HTML link
                    doi_val = get(item, "doi", nothing)
                    if doi_val isa String && !isempty(doi_val)
                        "https://doi.org/$(doi_val)"
                    else
                        get(get(item, "links", Dict()), "html", missing)
                    end
                end,
                "authors" => authors,
                "source" => "Zenodo",
                "id" => get(item, "id", missing)
            ))
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "Zenodo search failed" exception=e
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end