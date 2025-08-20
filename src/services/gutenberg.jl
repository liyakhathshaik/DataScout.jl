function search_gutenberg(query; max_results=10)
    url = "https://gutendex.com/books?search=$(HTTP.URIs.escapeuri(query))"
    
    try
        response = Core.api_request(:gutenberg, url)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        count = 0
        for item in data["results"]
            count >= max_results && break
            # Prioritize text/plain download links
            text_links = filter(f -> occursin("text/plain", f["mime_type"]), item["formats"])
            download_url = isempty(text_links) ? first(item["formats"])["url"] : first(text_links)["url"]
            
            authors = isempty(item["authors"]) ? missing : [a["name"] for a in item["authors"]]
            push!(results, Dict(
                "title" => get(item, "title", missing),
                "url" => download_url,
                "authors" => authors,
                "source" => "Project Gutenberg",
                "id" => string(get(item, "id", missing))
            ))
            count += 1
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "Gutenberg search failed" exception=e
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end