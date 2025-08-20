function search_whoogle(query; instance="https://whoogle.sdf.org", max_results=10)
    # Allow custom instance
    instance_url = if haskey(ENV, "WHOOGLE_INSTANCE")
        ENV["WHOOGLE_INSTANCE"]
    else
        instance
    end
    url = "$instance_url/search?q=$(HTTP.URIs.escapeuri(query))"
    
    try
        # Whoogle returns HTML, so we need to parse it
        response = Core.api_request(:whoogle, url)
        
        # Simplified HTML parsing (in practice, use a proper parser like Gumbo.jl)
        results = Dict{String,Any}[]
        for line in split(response, '\n')
            occursin(r"<div class=\"g\">", line) || continue
            m = match(r"<a href=\"(.*?)\".*?>(.*?)</a>", line)
            m === nothing && continue
            push!(results, Dict(
                "title" => strip(replace(m.captures[2], r"<.*?>" => "")),
                "url" => m.captures[1],
                "authors" => missing,
                "source" => "Whoogle",
                "id" => missing
            ))
            length(results) >= max_results && break
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "Whoogle search failed" exception=e
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end