## DataScout.jl Wiki

Your guide to what each feature does, why it exists, and how to use it effectively with clear examples.

### What is DataScout.jl?

DataScout.jl provides a unified, type-safe interface to search multiple scientific and open data sources from Julia. It normalizes results into a consistent schema and handles retries, rate limits, and configuration for you.

### Key Features

- **Unified search API**: One `search` function for all sources.
- **Consistent schema**: Results are normalized to the same columns.
- **Rate limiting**: Per-service throttling with persistent state.
- **Retries and error handling**: Resilient network calls with backoff.
- **Simple configuration**: API keys and settings via TOML in `~/.datascout`.
- **Pluggable HTTP handlers**: Injectable GET/POST for testing.

### Installation

```julia
using Pkg
Pkg.add("DataScout")
```

### Core API

- **Function**: `search(query::AbstractString; source::Symbol, max_results::Int=10, kwargs...)`
- **Behavior**:
  - Empty queries return an empty DataFrame (no error).
  - Throws for unsupported `source` or invalid arguments.
  - Delegates to the specific service implementation and normalizes results.

```julia
using DataScout

# Example
results = search("Julia programming language"; source=:wikipedia, max_results=5)
println(results)
```

### Result Schema

Every search returns a `DataFrame` with:

- `title::Union{String,Missing}`
- `url::Union{String,Missing}`
- `authors::Union{Vector{String},Missing}`
- `source::Union{String,Missing}`
- `id::Union{String,Missing}`

### Configuration

- **Files**: `~/.datascout/config.toml` and `~/.datascout/state.toml`
- **Set API keys**:

```julia
using DataScout
set_api_key!(:core, "YOUR_CORE_KEY")
key = get_api_key(:core)
```

- **Rate limits**:
  - Default: `core = 0.3` seconds, others default to `0.5` seconds.
  - Set in `~/.datascout/config.toml` under `[rate_limits]`.

- **Custom instances** (for `:searxng`, `:whoogle`):

```julia
ENV["SEARXNG_INSTANCE"] = "https://searx.example.org"
ENV["WHOOGLE_INSTANCE"] = "https://whoogle.example.org"
```

### How It Works (High Level)

- `DataScout.search` dispatches via a service registry defined in `src/DataScout.jl`.
- Requests go through `Services.Core.api_request` for rate limiting, retries, and error handling.
- Responses are parsed and normalized via `Normalize.dict_to_dataframe` to a common schema.

### Services: Why, When, How

Below are practical reasons to use each source and minimal examples.

#### CORE (`:core`)

- **Why**: High-quality index of academic works with direct download URLs.
- **When**: Literature reviews; need PDFs, titles, and authors.
- **How**:

```julia
using DataScout
set_api_key!(:core, "YOUR_CORE_KEY")
df = search("graph neural networks"; source=:core, max_results=5)
```

#### OpenAlex (`:openalex`)

- **Why**: Rich scholarly metadata; DOIs; broad coverage.
- **When**: Topic exploration; citation-based workflows.
- **How**:

```julia
df = search("federated learning"; source=:openalex, max_results=5)
```

#### Zenodo (`:zenodo`)

- **Why**: Research datasets and artifacts with persistent identifiers.
- **When**: Find datasets and supplementary research outputs.
- **How**:

```julia
df = search("climate dataset"; source=:zenodo, max_results=5)
```

#### Figshare (`:figshare`)

- **Why**: Media, datasets, and various research materials.
- **When**: Beyond papers: images, datasets, and more.
- **How**:

```julia
df = search("microscopy"; source=:figshare, max_results=5)
```

#### Project Gutenberg (`:gutenberg`)

- **Why**: Large corpus of public-domain ebooks.
- **When**: NLP experiments; classic texts.
- **How**:

```julia
df = search("sherlock holmes"; source=:gutenberg, max_results=5)
```

#### Open Library (`:openlibrary`)

- **Why**: Bibliographic and library catalog data.
- **When**: Book metadata for apps and integrations.
- **How**:

```julia
df = search("data visualization"; source=:openlibrary, max_results=5)
```

#### Wikipedia (`:wikipedia`)

- **Why**: Fast, encyclopedic overviews.
- **When**: UIs or chatbots needing quick lookups.
- **How**:

```julia
df = search("julia programming language"; source=:wikipedia, max_results=5)
```

#### DuckDuckGo (`:duckduckgo`)

- **Why**: General web results with privacy focus.
- **When**: Augment academic sources with broader context.
- **How**:

```julia
df = search("reproducible research tooling"; source=:duckduckgo, max_results=5)
```

#### SearxNG (`:searxng`)

- **Why**: Self-hostable meta-search; configurable instances.
- **When**: Enterprise environments and custom search aggregation.
- **How**:

```julia
ENV["SEARXNG_INSTANCE"] = "https://searx.example.org"
df = search("open data portals"; source=:searxng, max_results=5)
```

#### Whoogle (`:whoogle`)

- **Why**: Privacy-preserving Google front-end.
- **When**: Need Google-like results without direct queries to Google.
- **How**:

```julia
ENV["WHOOGLE_INSTANCE"] = "https://whoogle.example.org"
df = search("state of the art summarization"; source=:whoogle, max_results=5)
```

#### Internet Archive (`:internetarchive`)

- **Why**: Archives, media, historical documents.
- **When**: Historical datasets and media collections.
- **How**:

```julia
df = search("old computing magazines"; source=:internetarchive, max_results=5)
```

### Multi-Source Use Case

```julia
using DataFrames, DataScout

function search_multiple_sources(query, sources=[:wikipedia, :openalex, :zenodo])
    all_results = DataFrame()
    for source in sources
        try
            results = search(query; source=source, max_results=5)
            all_results = vcat(all_results, results, cols=:union)
        catch e
            @warn "Failed to search $source: $e"
        end
    end
    return all_results
end

df = search_multiple_sources("artificial intelligence")
```

### Reliability: Rate Limiting, Retries, Errors

- **Rate limiting**: Per-service delays from `Config.get_rate_limit`; state persisted to `~/.datascout/state.toml`.
- **Retries**: Exponential backoff, configurable attempts inside service core.
- **Errors**: Graceful empty results for empty queries; warnings and error logs for API issues.

### Troubleshooting

- Verify config: `DataScout.Config.get_config()`
- Check API key: `DataScout.get_api_key(:core)`
- Inspect rate limit: `DataScout.Config.get_rate_limit(:core)`
- Enable HTTP debug: `ENV["JULIA_DEBUG"] = "HTTP"`

### Contributing

See `README.md` for development setup. Typical flow:

```bash
git clone https://github.com/liyakhathshaik/DataScout.jl.git
cd DataScout.jl
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```


