# src/services.jl
module Services

# Import all service functions
include("services/core.jl")
include("services/openalex.jl")
include("services/zenodo.jl")
include("services/figshare.jl")
include("services/gutenberg.jl")
include("services/openlibrary.jl")
include("services/wikipedia.jl")
include("services/duckduckgo.jl")
include("services/searxng.jl")
include("services/whoogle.jl")
include("services/internetarchive.jl")

# Make Core module available
using .Core

# Export all search functions
export search_core, search_openalex, search_zenodo, search_figshare,
       search_gutenberg, search_openlibrary, search_wikipedia,
       search_duckduckgo, search_searxng, search_whoogle,
       search_internetarchive

end