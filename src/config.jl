module Config

using TOML
export get_api_key, set_api_key!, get_rate_limit

const CONFIG_DIR = joinpath(homedir(), ".datascout")
const CONFIG_PATH = joinpath(CONFIG_DIR, "config.toml")

function __init__()
    isdir(CONFIG_DIR) || mkdir(CONFIG_DIR)
    if !isfile(CONFIG_PATH)
        open(CONFIG_PATH, "w") do io
            println(io, """
            [api_keys]
            
            [rate_limits]
            core = 0.3
            """)
        end
    end
end

function get_config()
    TOML.parsefile(CONFIG_PATH)
end

function get_api_key(service::Symbol)
    config = get_config()
    get(config["api_keys"], string(service), nothing)
end

function set_api_key!(service::Symbol, key::String)
    config = get_config()
    config["api_keys"][string(service)] = key
    open(CONFIG_PATH, "w") do io
        TOML.print(io, config)
    end
end

function get_rate_limit(service::Symbol)
    config = get_config()
    get(get(config, "rate_limits", Dict()), string(service), 0.5)
end

# Initialize on load
__init__()

end