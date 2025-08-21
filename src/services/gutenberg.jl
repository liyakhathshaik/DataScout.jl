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
            # Gutendex returns a dict of format => url
            download_url = let formats = get(item, "formats", Dict{String,Any}())
                selected = missing
                for k in keys(formats)
                    if occursin("text/plain", String(k))
                        selected = formats[k]
                        break
                    end
                end
                if ismissing(selected)
                    isempty(formats) ? missing : first(values(formats))
                else
                    selected
                end
            end
            
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