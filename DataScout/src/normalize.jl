module Normalize

using DataFrames

const COMMON_SCHEMA = (
    title = Vector{Union{String,Missing}},
    url = Vector{Union{String,Missing}},
    authors = Vector{Union{Vector{String},Missing}},
    source = Vector{Union{String,Missing}},
    id = Vector{Union{String,Missing}}
)

function dict_to_dataframe(results::Vector{<:AbstractDict})
    df = DataFrame(;
        title = Union{String,Missing}[],
        url = Union{String,Missing}[],
        authors = Union{Vector{String},Missing}[],
        source = Union{String,Missing}[],
        id = Union{String,Missing}[]
    )
    
    for res in results
        row = (;
            title = get(res, "title", missing),
            url = get(res, "url", missing),
            authors = handle_authors(get(res, "authors", missing)),
            source = get(res, "source", missing),
            id = let id_val = get(res, "id", missing)
                if id_val isa Integer || id_val isa Number
                    string(id_val)
                else
                    id_val
                end
            end
        )
        push!(df, row)
    end
    return df
end

handle_authors(x::Vector) = isempty(x) ? missing : x
handle_authors(x::AbstractString) = [x]
handle_authors(::Missing) = missing

end # module