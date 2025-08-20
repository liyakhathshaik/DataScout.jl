function search_zenodo(query; max_results=10)
    url = "https://zenodo.org/api/records?q=$(HTTP.URIs.escapeuri(query))&size=$max_results"
    
    try
        response = Core.api_request(:zenodo, url)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        for item in data["hits"]["hits"]
            authors = if haskey(item["metadata"], "creators")
                [c.name for c in item["metadata"]["creators"]]
            else
                missing
            end
            push!(results, Dict(
                "title" => get(item["metadata"], "title", missing),
                "url" => get(item, "doi", missing) ? "https://doi.org/$(item["doi"])" : get(item, "links", Dict())["html"],
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