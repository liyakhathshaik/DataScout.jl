module Core

using HTTP, Dates, TOML
using ..Config

const HTTP_GET_REF = Ref{Function}()
HTTP_GET_REF[] = (url::String; headers=Dict()) -> HTTP.get(url; headers)
const HTTP_POST_REF = Ref{Function}()
HTTP_POST_REF[] = (url::String; headers=Dict(), body="") -> HTTP.post(url; headers, body=body)

function set_http_get!(f::Function)
    HTTP_GET_REF[] = f
end

function set_http_post!(f::Function)
    HTTP_POST_REF[] = f
end

function reset_http_handlers!()
    HTTP_GET_REF[] = (url::String; headers=Dict()) -> HTTP.get(url; headers)
    HTTP_POST_REF[] = (url::String; headers=Dict(), body="") -> HTTP.post(url; headers, body=body)
end

const STATE_LOCK = ReentrantLock()
const STATE = Dict{Symbol,DateTime}()
const STATE_PATH = joinpath(Config.CONFIG_DIR, "state.toml")

function __init__()
    load_state()
end

function load_state()
    if isfile(STATE_PATH)
        data = TOML.parsefile(STATE_PATH)
        for (k, v) in data
            STATE[Symbol(k)] = DateTime(v)
        end
    end
end

function save_state()
    data = Dict{String,String}()
    for (k, v) in STATE
        data[string(k)] = string(v)
    end
    open(STATE_PATH, "w") do io
        TOML.print(io, data)
    end
end

function api_request(service::Symbol, url::String; 
                    headers=Dict(), body="", method="GET", retries=3)
    # Rate limiting
    lock(STATE_LOCK) do
        last_time = get(STATE, service, nothing)
        delay = Config.get_rate_limit(service)
        if last_time !== nothing
            elapsed = (now() - last_time).value / 1000
            elapsed < delay && sleep(delay - elapsed)
        end
        STATE[service] = now()
        save_state()
    end

    # Request with retries
    local response
    for attempt in 1:retries
        try
            if method == "GET"
                response = HTTP_GET_REF[](url; headers=headers)
            else
                response = HTTP_POST_REF[](url; headers=headers, body=body)
            end
            if response.status == 200
                return String(response.body)
            else
                @warn "HTTP error: $(response.status)"
                throw(ErrorException("HTTP request failed with status $(response.status)"))
            end
        catch e
            @warn "Attempt $attempt failed: $e"
            sleep(2^attempt)  # Exponential backoff
        end
    end
    throw(ErrorException("Request failed after $retries attempts"))
end

# Initialize state on load
load_state()

end # module

# CORE API search function
function search_core(query; max_results=10)
    api_key = Config.get_api_key(:core)
    isnothing(api_key) && throw(ArgumentError("CORE API key not configured. Use DataScout.set_api_key!(:core, \"your-key\")"))
    
    # Input validation
    isempty(strip(query)) && throw(ArgumentError("Query cannot be empty"))
    max_results <= 0 && throw(ArgumentError("max_results must be positive"))
    
    url = "https://api.core.ac.uk/v3/search/works?q=$(HTTP.URIs.escapeuri(query))&limit=$max_results"
    headers = Dict("Authorization" => "Bearer $api_key")
    
    try
        response = Core.api_request(:core, url; headers)
        data = JSON3.read(response)
        
        results = Dict{String, Any}[]
        if !haskey(data, "results") || isempty(data["results"])
            @warn "No results found for query: $query"
            return Normalize.dict_to_dataframe(Dict{String, Any}[])
        end
        
        for item in data["results"]
            authors = if haskey(item, "authors") && !isempty(item["authors"])
                try
                    [get(a, "fullName", "") for a in item["authors"] if !isempty(get(a, "fullName", ""))]
                catch e
                    @debug "Error parsing authors" exception=e
                    missing
                end
            else
                missing
            end
            
            push!(results, Dict(
                "title" => get(item, "title", missing),
                "url" => get(item, "downloadUrl", missing),
                "authors" => authors,
                "source" => "CORE",
                "id" => string(get(item, "id", missing))
            ))
        end
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "CORE search failed" query=query exception=(e, catch_backtrace())
        return Normalize.dict_to_dataframe(Dict{String, Any}[])
    end
end