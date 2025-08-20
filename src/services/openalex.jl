function search_openalex(query; max_results=10)
    api_key = Config.get_api_key(:openalex)
    headers = isnothing(api_key) ? Dict() : Dict("Authorization" => "Bearer $api_key")
    
    url = "https://api.openalex.org/works?search=$(HTTP.URIs.escapeuri(query))&per_page=$max_results"
    
    try
        response = Core.api_request(:openalex, url; headers)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        if haskey(data, "results") && !isempty(data["results"])
            for item in data["results"]
                authors = if haskey(item, "authorships") && !isempty(item["authorships"])
                    try
                        [get(get(a, "author", Dict()), "display_name", "") for a in item["authorships"]]
                    catch
                        missing
                    end
                else
                    missing
                end
                
                # Convert DOI to proper URL
                doi_url = if haskey(item, "doi") && !isnothing(item["doi"]) && !isempty(item["doi"])
                    startswith(item["doi"], "https://doi.org/") ? item["doi"] : "https://doi.org/$(item["doi"])"
                else
                    get(item, "pdf_url", missing)
                end
                
                push!(results, Dict(
                    "title" => get(item, "title", missing),
                    "url" => doi_url,
                    "authors" => authors,
                    "source" => "OpenAlex",
                    "id" => get(item, "id", missing)
                ))
            end
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "OpenAlex search failed" exception=e
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end