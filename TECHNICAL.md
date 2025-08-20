# DataScout.jl - Technical Documentation

## Architecture Overview

DataScout.jl is designed with a modular architecture that separates concerns and ensures maintainability:

```
DataScout.jl/
├── src/
│   ├── DataScout.jl          # Main module and exports
│   ├── config.jl             # Configuration management
│   ├── core.jl               # Main module glue (search registry)
│   ├── normalize.jl          # Data normalization utilities
│   ├── services.jl           # Services module
│   └── services/             # Individual service implementations
│       ├── core.jl           # HTTP client, rate limiting, injectable handlers
│       ├── openalex.jl       # OpenAlex API client
│       ├── zenodo.jl         # Zenodo API client
│       └── ...               # Other service clients
├── test/                     # Comprehensive test suite
├── .github/workflows/        # CI/CD configuration
└── docs/                     # Documentation
```

## Core Components

### 1. Configuration System (`config.jl`)

The configuration system manages API keys and service settings:

```julia
module Config
    const CONFIG_DIR = joinpath(homedir(), ".datascout")
    const CONFIG_PATH = joinpath(CONFIG_DIR, "config.toml")
    
    # Automatic initialization
    function __init__()
        # Create config directory and default config
    end
    
    # API key management
    function set_api_key!(service::Symbol, key::String)
    function get_api_key(service::Symbol)
    
    # Rate limiting configuration
    function get_rate_limit(service::Symbol)
end
```

**Features:**
- Automatic config directory creation
- Persistent storage in TOML format
- Thread-safe operations
- Default rate limiting settings

### 2. Services Framework (`services/core.jl`)

The services framework provides common functionality for all API clients:

```julia
module Services.Core
    # Rate limiting state management
    const STATE_LOCK = ReentrantLock()
    const STATE = Dict{Symbol,DateTime}()
    
    # HTTP client with retry logic and injectable HTTP handlers
    function api_request(service::Symbol, url::String; kwargs...)
        # Rate limiting
        # Retry mechanism with exponential backoff
        # Error handling and logging
    end
end
```

**Features:**
- Per-service rate limiting
- Automatic retry with exponential backoff
- Thread-safe state management
- Persistent rate limit state across sessions
 - Injectable `GET`/`POST` handlers for testability

### 3. Data Normalization (`normalize.jl`)

All search results are normalized to a consistent schema:

```julia
module Normalize
    const COMMON_SCHEMA = (
        title = Vector{Union{String,Missing}},
        url = Vector{Union{String,Missing}},
        authors = Vector{Union{Vector{String},Missing}},
        source = Vector{Union{String,Missing}},
        id = Vector{Union{String,Missing}}
    )
    
    function dict_to_dataframe(results::Vector{<:AbstractDict})
        # Convert heterogeneous API responses to DataFrame
    end
end
```

**Schema Design:**
- **title**: Resource title/name
- **url**: Direct access URL
- **authors**: List of authors (when available)
- **source**: Source service name
- **id**: Unique identifier from source

### 4. Service Registry (`DataScout.jl`)

The main module maintains a registry of available services:

```julia
const SERVICE_REGISTRY = Dict{Symbol,Function}(
    :core => search_core,
    :openalex => search_openalex,
    :zenodo => search_zenodo,
    # ... other services
)

function search(query::AbstractString; source::Symbol, max_results::Int=10, kwargs...)
    if isempty(strip(query))
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
    func = get(SERVICE_REGISTRY, source, nothing)
    func === nothing && throw(ArgumentError("Unsupported source: $source"))
    return func(query; max_results=max_results, kwargs...)
end
```

## Service Implementation Pattern

Each service follows a consistent implementation pattern:

```julia
function search_servicename(query; max_results=10, kwargs...)
    # 1. URL construction
    url = build_api_url(query, max_results)
    
    # 2. Authentication (if required)
    headers = get_auth_headers()
    
    # 3. API request with error handling
    try
        response = Services.Core.api_request(:servicename, url; headers)
        data = JSON3.read(response)
        
        # 4. Data extraction and normalization
        results = extract_results(data)
        return Normalize.dict_to_dataframe(results)
    catch e
        @error "Service search failed" exception=(e, catch_backtrace())
        return Normalize.dict_to_dataframe(Dict{String,Any}[])
    end
end
```

## Error Handling Strategy

DataScout.jl implements a multi-layer error handling strategy:

### 1. Network Level
- HTTP request retries with exponential backoff
- Timeout handling
- Connection error recovery

### 2. API Level
- HTTP status code validation
- API response format validation
- Rate limit respect and retry

### 3. Data Level
- Missing field handling
- Type conversion safety
- Schema validation

### 4. Application Level
- Graceful degradation (return empty results)
- Comprehensive error logging
- User-friendly error messages

## Rate Limiting Implementation

Rate limiting is implemented at the service level:

```julia
function api_request(service::Symbol, url::String; kwargs...)
    lock(STATE_LOCK) do
        last_time = get(STATE, service, nothing)
        delay = Config.get_rate_limit(service)
        
        if last_time !== nothing
            elapsed = (now() - last_time).value / 1000
            if elapsed < delay
                sleep(delay - elapsed)
            end
        end
        
        STATE[service] = now()
        save_state()  # Persist across sessions
    end
    
    # Make request...
end
```

**Features:**
- Per-service rate limiting
- Configurable rate limits
- Persistent state across sessions
- Thread-safe implementation

## Testing Strategy

DataScout.jl uses a comprehensive testing approach:

### 1. Unit Tests
- Individual function testing
- Edge case coverage
- Error condition testing

### 2. Integration Tests
- Service API mocking
- End-to-end workflows
- Configuration management

### 3. Mocking Strategy
Prefer dependency injection over patching. The core service exposes setters:

```julia
using DataScout.Services.Core

set_http_get!((url::String; headers=Dict()) -> HTTP.Response(200, "{}"))
try
    result = api_request(:test, "http://example.com")
finally
    reset_http_handlers!()
end
```

### 4. Coverage Targets
- **Line Coverage**: 80%+
- **Branch Coverage**: 75%+
- **Function Coverage**: 95%+

## CI/CD Pipeline

The project uses GitHub Actions for continuous integration:

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        julia-version: ['1.6', '1.9', '1.10']
        os: [ubuntu-latest, windows-latest, macOS-latest]
    
    steps:
      - uses: actions/checkout@v4
      - uses: julia-actions/setup-julia@v1
      - uses: julia-actions/julia-buildpkg@v1
      - uses: julia-actions/julia-runtest@v1
        with:
          coverage: true
      - uses: codecov/codecov-action@v3
```

**Features:**
- Multi-version Julia testing (1.6, 1.9, 1.10)
- Multi-platform testing (Linux, Windows, macOS)
- Automated code coverage reporting
- Dependency caching for faster builds

## Performance Considerations

### 1. Memory Management
- Efficient DataFrame construction
- Minimal string allocations
- Proper garbage collection

### 2. Network Efficiency
- Connection reuse where possible
- Appropriate timeout settings
- Compression support

### 3. Rate Limiting Optimization
- Minimal overhead rate limiting
- Efficient state management
- Persistent state to avoid unnecessary delays (state persisted in `~/.datascout/state.toml`)

## Security Considerations

### 1. API Key Management
- Secure storage in user home directory
- No API keys in code or logs
- Proper file permissions on config files
- Access via `DataScout.set_api_key!` and `DataScout.get_api_key`

### 2. Network Security
- HTTPS-only API communication
- Certificate validation
- No sensitive data in URLs

### 3. Input Validation
- Query sanitization
- URL encoding
- Parameter validation

## Extension Points

DataScout.jl is designed for easy extension:

### 1. Adding New Services
```julia
# 1. Create service file: src/services/newservice.jl
function search_newservice(query; max_results=10)
    # Implementation
end

# 2. Add to services.jl
include("services/newservice.jl")
export search_newservice

# 3. Register in DataScout.jl
SERVICE_REGISTRY[:newservice] = search_newservice
```

### 2. Custom Data Processing
```julia
# Custom normalization for specific use cases
function custom_normalize(data, source_type)
    # Custom processing logic
    return Normalize.dict_to_dataframe(processed_data)
end
```

### 3. Configuration Extensions
```julia
# Additional config sections
function get_custom_config(service::Symbol)
    config = Config.get_config()
    return get(config, "custom_section", Dict())
end
```

## Debugging and Troubleshooting

### 1. Logging
DataScout.jl uses Julia's logging system:

```julia
using Logging

# Enable debug logging
global_logger(ConsoleLogger(Logging.Debug))

# Service-specific logging
@debug "API request" url=url headers=headers
@info "Search completed" source=source results=nrow(results)
@error "Search failed" exception=(e, catch_backtrace())
```

### 2. Configuration Debugging
```julia
# Check configuration
DataScout.Config.get_config()

# Verify API keys
DataScout.get_api_key(:core)

# Check rate limits
DataScout.Config.get_rate_limit(:core)
```

### 3. Network Debugging
```julia
# Enable HTTP request logging
ENV["JULIA_DEBUG"] = "HTTP"

# Manual API testing
using HTTP, JSON3
response = HTTP.get("https://api.example.com/test")
```

## Performance Benchmarks

Typical performance characteristics:

- **Configuration load**: < 1ms
- **API request (cached)**: 50-200ms
- **Data normalization**: 1-10ms per 100 results
- **Memory usage**: ~10MB base + ~1KB per result

## Future Enhancements

Planned improvements:

1. **Async Support**: Concurrent searches across multiple services
2. **Caching Layer**: Local result caching with TTL
3. **Advanced Filtering**: Post-search filtering and ranking
4. **Batch Operations**: Multiple queries in single requests
5. **Plugin System**: Dynamic service loading
6. **GraphQL Support**: Modern API interface option

---

This technical documentation provides a comprehensive overview of DataScout.jl's internal architecture and implementation details for developers and contributors.