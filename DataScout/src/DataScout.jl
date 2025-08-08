module DataScout

using HTTP, JSON3, DataFrames, Dates, TOML
export search, set_api_key!, get_api_key  
# Core functionality
include("config.jl")
include("core.jl")
include("normalize.jl")
include("services.jl")
using .Services

# Service implementations
service_files = [
    "core.jl", "openalex.jl", "zenodo.jl", "figshare.jl",
    "gutenberg.jl", "openlibrary.jl", "wikipedia.jl",
    "duckduckgo.jl", "searxng.jl", "whoogle.jl", "internetarchive.jl"
]

for file in service_files
    include(joinpath("services", file))
end

# Service registry
const SERVICE_REGISTRY = Dict{Symbol,Function}(
    :core => search_core,
    :openalex => search_openalex,
    :zenodo => search_zenodo,
    :figshare => search_figshare,
    :gutenberg => search_gutenberg,
    :openlibrary => search_openlibrary,
    :wikipedia => search_wikipedia,
    :duckduckgo => search_duckduckgo,
    :searxng => search_searxng,
    :whoogle => search_whoogle,
    :internetarchive => search_internetarchive
)

export search

function search(query::AbstractString; source::Symbol, max_results::Int=10, kwargs...)
    func = get(SERVICE_REGISTRY, source, nothing)
    func === nothing && throw(ArgumentError("Unsupported source: $source"))
    return func(query; max_results=max_results, kwargs...)
end

end # module