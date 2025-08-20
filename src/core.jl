# Core search functionality - redirects to Services module
# This file maintains backwards compatibility

"""
    search_core(query; max_results=10)

Search the CORE academic database for research papers.

This function is deprecated. Use `search(query; source=:core, max_results=max_results)` instead.
"""
function search_core(query; max_results=10)
    @warn "search_core is deprecated. Use search(query; source=:core, max_results=max_results) instead."
    return Services.search_core(query; max_results=max_results)
end