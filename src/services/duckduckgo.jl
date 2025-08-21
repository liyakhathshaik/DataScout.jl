function search_duckduckgo(query; max_results=10)
    url = "https://api.duckduckgo.com/?q=$(HTTP.URIs.escapeuri(query))&format=json&no_redirect=1"
    
    try
        response = Core.api_request(:duckduckgo, url)
        data = JSON3.read(response)
        
        results = Dict{String,Any}[]
        # DuckDuckGo returns one primary result + related topics
        if !isempty(data["Results"])
            push!(results, Dict(
                "title" => get(data, "Heading", missing),
                "url" => get(data, "AbstractURL", missing),
                "authors" => missing,
                "source" => "DuckDuckGo",
                "id" => missing
            ))
        end
        
        # Add related topics
        for topic in data["RelatedTopics"]
            if haskey(topic, "Topics")
                for subtopic in topic["Topics"]
                    push!(results, Dict(
                        "title" => get(subtopic, "Text", missing),
                        "url" => get(subtopic, "FirstURL", missing),
                        "authors" => missing,
                        "source" => "DuckDuckGo",
                        "id" => missing
                    ))
                end
            else
                push!(results, Dict(
                    "title" => get(topic, "Text", missing),
                    "url" => get(topic, "FirstURL", missing),
                    "authors" => missing,
                    "source" => "DuckDuckGo",
                    "id" => missing
                ))
            end
            length(results) >= max_results && break
        end
        return Normalize.dict_to_dataframe(results[1:min(end, max_results)])
    catch e
        @error "DuckDuckGo search failed" exception=e
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end