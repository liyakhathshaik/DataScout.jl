function search_openalex(query; max_results=10)
    api_key = Config.get_api_key(:openalex)
    headers = isnothing(api_key) ? Dict() : Dict("Authorization" => "Bearer $api_key")
    
    url = "https://api.openalex.org/works?search=$(HTTP.URIs.escapeuri(query))&per_page=$max_results"
    
    try
        response = Core.api_request(:openalex, url; headers)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        for item in data["results"]
            authors = isempty(item.authorships) ? missing : [a.author.display_name for a in item.authorships]
            # Convert DOI to proper URL
            doi_url = if !isempty(item.doi)
                "https://doi.org/$(item.doi)"
            else
                get(item, :pdf_url, missing)
            end
            push!(results, Dict(
                "title" => get(item, :title, missing),
                "url" => doi_url,
                "authors" => authors,
                "source" => "OpenAlex",
                "id" => get(item, :id, missing)
            ))
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "OpenAlex search failed" exception=e
        return Normalize.dict_to_dataframe([])
    end
end