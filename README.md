# DataScout.jl 🔍

[![CI](https://github.com/liyakhathshaik/DataScout.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/liyakhathshaik/DataScout.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/liyakhathshaik/DataScout.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/liyakhathshaik/DataScout.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> A unified Julia package for searching scientific repositories, libraries, and databases

DataScout.jl provides a consistent interface to search across multiple scientific and academic data sources. Whether you're looking for research papers, books, datasets, or web content, DataScout.jl makes it easy to find what you need.

## Features

- **Unified Interface**: Search multiple sources with a single, consistent API
- **Multiple Sources**: Support for 11+ different data sources
- **Rate Limiting**: Built-in rate limiting to respect API limits
- **Error Handling**: Robust error handling and retry mechanisms
- **Flexible Configuration**: Easy API key management and customization
- **Type Safety**: Full Julia type annotations and safety

## Installation

```julia
using Pkg
Pkg.add("DataScout")
```

Or from the Julia REPL:

```julia
] add DataScout
```

## Quick Start

```julia
using DataScout

# Search Wikipedia
results = search("Julia programming language", source=:wikipedia, max_results=5)

# Search academic papers (requires API key)
set_api_key!(:core, "your-core-api-key")
papers = search("machine learning", source=:core, max_results=10)

# Search books
books = search("data science", source=:openlibrary, max_results=5)

# View results
println(results)
```

Tip: An empty query returns an empty DataFrame (no error), so you can safely pass user input without pre-validation.

## Supported Sources

| Source | Symbol | API Key Required | Description |
|--------|--------|------------------|-------------|
| [CORE](https://core.ac.uk/) | `:core` | ✅ | Academic papers and research articles |
| [OpenAlex](https://openalex.org/) | `:openalex` | ❌ | Scholarly works and publications |
| [Zenodo](https://zenodo.org/) | `:zenodo` | ❌ | Research data and publications |
| [Figshare](https://figshare.com/) | `:figshare` | ❌ | Research outputs and datasets |
| [Project Gutenberg](https://www.gutenberg.org/) | `:gutenberg` | ❌ | Free ebooks |
| [Open Library](https://openlibrary.org/) | `:openlibrary` | ❌ | Books and library catalog |
| [Wikipedia](https://wikipedia.org/) | `:wikipedia` | ❌ | Encyclopedia articles |
| [DuckDuckGo](https://duckduckgo.com/) | `:duckduckgo` | ❌ | Web search results |
| [SearxNG](https://searx.space/) | `:searxng` | ❌ | Privacy-focused search |
| [Whoogle](https://github.com/benbusby/whoogle-search) | `:whoogle` | ❌ | Privacy-focused Google search |
| [Internet Archive](https://archive.org/) | `:internetarchive` | ❌ | Digital library and archives |

Why DataScout: unified schema across sources, built-in retries and rate limiting, simple API key management, and strong error handling.

## Configuration

### API Keys

Some services require API keys for access:

```julia
# Set API keys
set_api_key!(:core, "your-core-api-key")
set_api_key!(:openalex, "your-openalex-api-key")  # Optional

# Get API keys
api_key = get_api_key(:core)
```

API keys are stored in `~/.datascout/config.toml` and persist between sessions.

### Custom Instances

For services like SearxNG and Whoogle, you can specify custom instances:

```julia
# Using environment variables
ENV["SEARXNG_INSTANCE"] = "https://my-searxng-instance.com"
ENV["WHOOGLE_INSTANCE"] = "https://my-whoogle-instance.com"

# Or pass as parameters
results = search("query", source=:searxng, instance="https://custom-instance.com")
```

## Usage Examples

### Basic Search

```julia
using DataScout

# Simple Wikipedia search
results = search("quantum computing", source=:wikipedia)
println("Found $(nrow(results)) results")
println(results.title[1])  # First result title
println(results.url[1])    # First result URL
```

### Academic Research

```julia
# Search for academic papers
set_api_key!(:core, "your-api-key")
papers = search("climate change", source=:core, max_results=20)

# Filter results
recent_papers = filter(row -> !ismissing(row.authors), papers)

# Display results
for i in 1:min(5, nrow(papers))
    println("Title: $(papers.title[i])")
    println("Authors: $(papers.authors[i])")
    println("URL: $(papers.url[i])")
    println("---")
end
```

### Multi-Source Search

```julia
function search_multiple_sources(query, sources=[:wikipedia, :openalex, :zenodo])
    all_results = DataFrame()
    
    for source in sources
        try
            results = search(query, source=source, max_results=5)
            all_results = vcat(all_results, results, cols=:union)
        catch e
            @warn "Failed to search $source: $e"
        end
    end
    
    return all_results
end

# Search across multiple sources
results = search_multiple_sources("artificial intelligence")
```

### Real-World Use Cases by Source

- **CORE (`:core`)**: literature reviews, academic search portals, or internal tools where PDF links and authors are important.
  - Why: high-quality academic index with direct download URLs.
  - How:
    ```julia
    set_api_key!(:core, "YOUR_CORE_KEY")
    df = search("graph neural networks", source=:core, max_results=5)
    ```

- **OpenAlex (`:openalex`)**: topic exploration, citation-based workflows, profile building.
  - Why: rich scholarly metadata; DOI normalization to `https://doi.org/...`.
  - How:
    ```julia
    df = search("federated learning", source=:openalex, max_results=5)
    ```

- **Zenodo (`:zenodo`)**: dataset discovery, research artifacts in pipelines.
  - Why: research outputs with persistent identifiers.
  - How:
    ```julia
    df = search("climate dataset", source=:zenodo, max_results=5)
    ```

- **Figshare (`:figshare`)**: media, datasets, and supplementary materials.
  - Why: broad research outputs beyond papers.
  - How:
    ```julia
    df = search("microscopy", source=:figshare, max_results=5)
    ```

- **Project Gutenberg (`:gutenberg`)**: classic texts for NLP experiments and demos.
  - Why: public-domain ebooks at scale.
  - How:
    ```julia
    df = search("sherlock holmes", source=:gutenberg, max_results=5)
    ```

- **Open Library (`:openlibrary`)**: bibliographic enrichment and library apps.
  - Why: book metadata for integrations and lookups.
  - How:
    ```julia
    df = search("data visualization", source=:openlibrary, max_results=5)
    ```

- **Wikipedia (`:wikipedia`)**: quick encyclopedic lookups in UIs or chatbots.
  - Why: broad coverage, fast responses.
  - How:
    ```julia
    df = search("julia programming language", source=:wikipedia, max_results=5)
    ```

- **DuckDuckGo (`:duckduckgo`)**: general web results with privacy focus.
  - Why: augment academic results with broader context.
  - How:
    ```julia
    df = search("reproducible research tooling", source=:duckduckgo, max_results=5)
    ```

- **SearxNG (`:searxng`)**: meta-search with custom instances for enterprise.
  - Why: configurable, self-hostable meta search.
  - How:
    ```julia
    ENV["SEARXNG_INSTANCE"] = "https://searx.example.org"
    df = search("open data portals", source=:searxng, max_results=5)
    ```

- **Whoogle (`:whoogle`)**: privacy-preserving Google front-end.
  - Why: keep queries private while leveraging Google results.
  - How:
    ```julia
    ENV["WHOOGLE_INSTANCE"] = "https://whoogle.example.org"
    df = search("state of the art summarization", source=:whoogle, max_results=5)
    ```

- **Internet Archive (`:internetarchive`)**: archives, media, and historical documents.
  - Why: rich historical datasets and media collections.
  - How:
    ```julia
    df = search("old computing magazines", source=:internetarchive, max_results=5)
    ```

## Result Format

All search functions return a `DataFrame` with the following columns:

- `title::Union{String, Missing}` - Title of the result
- `url::Union{String, Missing}` - URL to access the resource
- `authors::Union{Vector{String}, Missing}` - List of authors (when available)
- `source::Union{String, Missing}` - Source name
- `id::Union{String, Missing}` - Unique identifier from the source

## Error Handling

DataScout.jl includes comprehensive error handling:

```julia
# Graceful handling of network errors
try
    results = search("test query", source=:core)
catch e
    @error "Search failed: $e"
    results = DataFrame()  # Empty results
end

# Built-in retry mechanism for transient failures
# Automatic rate limiting to respect API limits
# Detailed error logging for debugging
```

Behavioral guarantees:
- Empty queries return an empty standardized DataFrame (no exceptions).
- All sources normalize to the same schema.
- Transient failures are retried with exponential backoff.

## Performance and Rate Limiting

DataScout.jl automatically handles rate limiting for each service:

- **CORE**: 0.3 seconds between requests (default)
- **Other services**: 0.5 seconds between requests (default)
- **Retry mechanism**: 3 attempts with exponential backoff
- **Configurable**: Adjust rate limits in `~/.datascout/config.toml`

Rate-limiting state is persisted in `~/.datascout/state.toml` to smooth behavior across sessions.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
git clone https://github.com/liyakhathshaik/DataScout.jl.git
cd DataScout.jl
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using Pkg; Pkg.test()'
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to all the open data providers and APIs that make this package possible
- Inspired by the need for unified access to scientific literature and data
- Built with ❤️ for the Julia community

## Support

- 📖 [Documentation](https://github.com/liyakhathshaik/DataScout.jl)
- 🐛 [Issue Tracker](https://github.com/liyakhathshaik/DataScout.jl/issues)
- 💬 [Discussions](https://github.com/liyakhathshaik/DataScout.jl/discussions)

---

**DataScout.jl** - Making scientific data discovery simple and unified! 🔍✨