module Core

using HTTP, Dates, TOML
import ...Config

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
                response = HTTP.get(url; headers)
            else
                response = HTTP.post(url; headers, body=body)
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