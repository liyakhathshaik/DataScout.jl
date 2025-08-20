using DataScout
using Test
using HTTP
using JSON3
using Mocking
using DataFrames

Mocking.activate()

@testset "Service Tests" begin
    @testset "Main Search Function" begin
        # Test invalid source
        @test_throws ArgumentError DataScout.search("test", source=:invalid)
        
        # Test empty query handling
        @test_nowarn DataScout.search("", source=:wikipedia)
    end

    @testset "CORE Service" begin
        # Mock CORE API response
        # Inject handler for CORE
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("core.ac.uk", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "results" => [
                        Dict(
                            "title" => "Test 2214: Kubota M7-132",
                            "downloadUrl" => "https://core.ac.uk/download/323061825.pdf",
                            "authors" => [Dict("fullName" => "Test Author")],
                            "id" => "323061825"
                        )
                    ]
                )))
            end
            return HTTP.Response(404)
        end)

        try
            # Set a dummy API key for testing
            DataScout.set_api_key!(:core, "test_key")
            results = DataScout.search("test", source=:core, max_results=1)
            @test nrow(results) == 1
            @test results.title[1] == "Test 2214: Kubota M7-132"
            @test results.url[1] == "https://core.ac.uk/download/323061825.pdf"
            @test results.authors[1] == ["Test Author"]
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "OpenAlex Service" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("openalex.org", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "results" => [
                        Dict(
                            "title" => "Test Research Paper",
                            "doi" => "10.1234/test",
                            "authorships" => [
                                Dict("author" => Dict("display_name" => "Jane Doe"))
                            ],
                            "id" => "W123456789"
                        )
                    ]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            results = DataScout.search("test", source=:openalex, max_results=1)
            @test nrow(results) == 1
            @test results.title[1] == "Test Research Paper"
            @test startswith(results.url[1], "https://doi.org/")
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Wikipedia Service" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("wikipedia.org", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "query" => Dict(
                        "search" => [
                            Dict(
                                "title" => "Julia (programming language)",
                                "pageid" => 123456
                            )
                        ]
                    )
                )))
            end
            return HTTP.Response(404)
        end)
        try
            results = DataScout.search("Julia", source=:wikipedia, max_results=1)
            @test nrow(results) == 1
            @test results.title[1] == "Julia (programming language)"
            @test occursin("wikipedia.org", results.url[1])
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Error Handling" begin
        # Test network error handling
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> throw(HTTP.RequestError("Network error")))
        try
            results = DataScout.search("test", source=:wikipedia)
            @test nrow(results) == 0
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Data Normalization" begin
        # Test empty results
        empty_results = DataScout.Normalize.dict_to_dataframe(Dict{String,Any}[])
        @test nrow(empty_results) == 0
        @test ncol(empty_results) == 5  # title, url, authors, source, id

        # Test with sample data
        sample_data = [
            Dict("title" => "Test Paper", "url" => "http://example.com", 
                 "authors" => ["Author 1"], "source" => "Test", "id" => "123"),
            Dict("title" => missing, "url" => missing, 
                 "authors" => missing, "source" => "Test", "id" => missing)
        ]
        
        df = DataScout.Normalize.dict_to_dataframe(sample_data)
        @test nrow(df) == 2
        @test df.title[1] == "Test Paper"
        @test ismissing(df.title[2])
    end
end