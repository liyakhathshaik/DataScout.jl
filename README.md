# DataScout.jl 🔍

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> Search scientific repositories with one unified interface

## Installation
julia
] add DataScout

#Quick Start
using DataScout

# Search DuckDuckGo
results = duckduckgo_search("Julia programming")

# View results
println(results)


# Supported Services
Service	Function
DuckDuckGo	duckduckgo_search
CORE	core_search
Project Gutenberg	gutenberg_search
OpenAlex	openalex_search
Wikipedia	wikipedia_search
Zenodo	zenodo_search
Figshare	figshare_search
Internet Archive	internetarchive_search


=

# Need Help?
Open an issue:
https://github.com/liyakhathshaik/DataScout.jl/issues
Open Library	openlibrary_search
SearxNG	searxng_search
Whoogle	whoogle_search



