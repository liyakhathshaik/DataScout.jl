module DataScout

using HTTP, JSON3, DataFrames, Dates, TOML

# Core functionality
include("config.jl")
include("normalize.jl")
include("services.jl")
using .Services
using .Normalize

# Export main functions
export search, set_api_key!, get_api_key

# Service registry - import functions from Services module
const SERVICE_REGISTRY = Dict{Symbol,Function}(
    :core => Services.search_core,
    :openalex => Services.search_openalex,
    :zenodo => Services.search_zenodo,
    :figshare => Services.search_figshare,
    :gutenberg => Services.search_gutenberg,
    :openlibrary => Services.search_openlibrary,
    :wikipedia => Services.search_wikipedia,
    :duckduckgo => Services.search_duckduckgo,
    :searxng => Services.search_searxng,
    :whoogle => Services.search_whoogle,
    :internetarchive => Services.search_internetarchive
)

"""
    search(query::AbstractString; source::Symbol, max_results::Int=10, kwargs...)

Search for academic papers and resources across various databases.

# Arguments
- `query::AbstractString`: The search query string
- `source::Symbol`: The data source to search (e.g., :core, :openalex, :zenodo)
- `max_results::Int`: Maximum number of results to return (default: 10)
- `kwargs...`: Additional keyword arguments specific to each service

# Returns
- `DataFrame`: Standardized results with columns: title, url, authors, source, id

# Example
```julia
using DataScout
DataScout.set_api_key!(:core, "your-api-key")
results = search("machine learning"; source=:core, max_results=5)
```
"""
function search(query::AbstractString; source::Symbol, max_results::Int=10, kwargs...)
    # Input validation
    if isempty(strip(query))
        # Gracefully return no results for empty queries
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
    max_results <= 0 && throw(ArgumentError("max_results must be positive"))
    
    func = get(SERVICE_REGISTRY, source, nothing)
    func === nothing && throw(ArgumentError("Unsupported source: $source. Available sources: $(keys(SERVICE_REGISTRY))"))
    
    try
        return func(query; max_results=max_results, kwargs...)
    catch e
        @error "Search failed for source $source" exception=(e, catch_backtrace())
        rethrow(e)
    end
end

# Convenience functions for API key management
function set_api_key!(service::Symbol, key::String)
    Config.set_api_key!(service, key)
end

function get_api_key(service::Symbol)
    Config.get_api_key(service)
end

end # module