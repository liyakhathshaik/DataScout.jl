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

        # Test invalid max_results
        @test_throws ArgumentError DataScout.search("abc", source=:wikipedia, max_results=0)

        # Test supported sources list via thrown error message content
        try
            DataScout.search("x", source=:__not_source__)
        catch e
            @test occursin("Unsupported source", sprint(showerror, e))
        end
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

    @testset "Zenodo Service" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("zenodo.org", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "hits" => Dict(
                        "hits" => [
                            Dict(
                                "id" => 111,
                                "doi" => "10.5281/zenodo.12345",
                                "links" => Dict("html" => "https://zenodo.org/record/111"),
                                "metadata" => Dict(
                                    "title" => "Zenodo Sample",
                                    "creators" => [Dict("name" => "Z Author")]
                                )
                            )
                        ]
                    )
                )))
            end
            return HTTP.Response(404)
        end)
        try
            results = DataScout.search("zen", source=:zenodo, max_results=1)
            @test nrow(results) == 1
            @test occursin("doi.org", String(results.url[1]))
            @test results.authors[1] == ["Z Author"]
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Figshare Service" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("figshare.com", url)
                return HTTP.Response(200, JSON3.write([
                    Dict(
                        "id" => 222,
                        "title" => "Figshare Item",
                        "url" => "https://figshare.com/articles/222",
                        "authors" => [Dict("full_name" => "F Author")]
                    )
                ]))
            end
            return HTTP.Response(404)
        end)
        try
            results = DataScout.search("fig", source=:figshare, max_results=1)
            @test nrow(results) == 1
            @test results.title[1] == "Figshare Item"
            @test results.authors[1] == ["F Author"]
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Gutenberg Service" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("gutendex.com", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "results" => [
                        Dict(
                            "id" => 333,
                            "title" => "Gutenberg Book",
                            "authors" => [Dict("name" => "G Author")],
                            "formats" => Dict(
                                "text/plain; charset=utf-8" => "https://example.com/book.txt",
                                "application/epub+zip" => "https://example.com/book.epub"
                            )
                        )
                    ]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            results = DataScout.search("book", source=:gutenberg, max_results=1)
            @test nrow(results) == 1
            @test endswith(String(results.url[1]), ".txt")
            @test results.authors[1] == ["G Author"]
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Gutenberg Missing Formats" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("gutendex.com", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "results" => [Dict("id" => 1, "title" => "No Formats", "authors" => Any[], "formats" => Dict{String,Any}())]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            df = DataScout.search("q", source=:gutenberg, max_results=1)
            @test ismissing(df.url[1])
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Open Library Service" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("openlibrary.org", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "docs" => [
                        Dict("title" => "OL Work", "key" => "OL12345W", "author_name" => ["OL Author"]) 
                    ]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            results = DataScout.search("ol", source=:openlibrary, max_results=1)
            @test nrow(results) == 1
            @test occursin("openlibrary.org/works/OL12345W", String(results.url[1]))
            @test results.authors[1] == ["OL Author"]
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Open Library Missing Authors" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("openlibrary.org", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "docs" => [Dict("title" => "No Authors", "key" => "OLXW")] 
                )))
            end
            return HTTP.Response(404)
        end)
        try
            df = DataScout.search("q", source=:openlibrary, max_results=1)
            @test ismissing(df.authors[1])
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "DuckDuckGo Service" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("api.duckduckgo.com", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "Heading" => "Duck Result",
                    "AbstractURL" => "https://example.com/duck",
                    "Results" => [Dict()],
                    "RelatedTopics" => [
                        Dict("Text" => "Topic 1", "FirstURL" => "https://example.com/t1"),
                        Dict("Topics" => [Dict("Text" => "Sub 1", "FirstURL" => "https://example.com/s1")])
                    ]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            results = DataScout.search("duck", source=:duckduckgo, max_results=3)
            @test nrow(results) >= 1
            @test results.source[1] == "DuckDuckGo"
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "SearxNG Env Override" begin
        # Ensure env var override is respected by the service by asserting URL used
        ENV["SEARXNG_INSTANCE"] = "https://searx.example.org"
        captured_url = Ref("")
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            captured_url[] = url
            HTTP.Response(200, JSON3.write(Dict("results" => [Dict("title" => "ok", "url" => "u")])) )
        end)
        try
            _ = DataScout.search("q", source=:searxng, max_results=1)
            @test startswith(captured_url[], "https://searx.example.org")
        finally
            delete!(ENV, "SEARXNG_INSTANCE")
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Whoogle Env Override" begin
        ENV["WHOOGLE_INSTANCE"] = "https://whoogle.example.org"
        captured_url = Ref("")
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            captured_url[] = url
            return HTTP.Response(200, "<div class=\"g\"><a href=\"https://x\">X</a></div>")
        end)
        try
            _ = DataScout.search("q", source=:whoogle, max_results=1)
            @test startswith(captured_url[], "https://whoogle.example.org")
        finally
            delete!(ENV, "WHOOGLE_INSTANCE")
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "OpenAlex without DOI" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("openalex.org", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "results" => [Dict(
                        "title" => "No DOI", "pdf_url" => "https://x.pdf", "authorships" => []
                    )]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            df = DataScout.search("q", source=:openalex, max_results=1)
            @test df.url[1] == "https://x.pdf"
            @test ismissing(df.authors[1])
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "SearxNG Service" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("/search?", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "results" => [
                        Dict("title" => "Sx Title", "url" => "https://example.com/sx")
                    ]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            results = DataScout.search("sx", source=:searxng, max_results=1)
            @test nrow(results) == 1
            @test results.source[1] == "SearxNG"
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Whoogle Service" begin
        # Provide simplified HTML lines that contain <div class="g"> and an <a href>
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("whoogle", url)
                html = """
                <html>
                <body>
                <div class="g"><a href="https://example.com/w1">Whoogle <b>Result</b></a></div>
                </body>
                </html>
                """
                return HTTP.Response(200, html)
            end
            return HTTP.Response(404)
        end)
        try
            results = DataScout.search("wg", source=:whoogle, max_results=1)
            @test nrow(results) == 1
            @test results.source[1] == "Whoogle"
            @test results.url[1] == "https://example.com/w1"
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Internet Archive Service" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("archive.org", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "response" => Dict(
                        "docs" => [
                            Dict("identifier" => "ia123", "title" => "IA Item", "creator" => "IA Author")
                        ]
                    )
                )))
            end
            return HTTP.Response(404)
        end)
        try
            results = DataScout.search("ia", source=:internetarchive, max_results=1)
            @test nrow(results) == 1
            @test occursin("archive.org/details/ia123", String(results.url[1]))
            @test results.authors[1] == ["IA Author"]
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Internet Archive Array Creators" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("archive.org", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "response" => Dict("docs" => [Dict("identifier" => "iax", "title" => "X", "creator" => ["A","B"])])
                )))
            end
            return HTTP.Response(404)
        end)
        try
            df = DataScout.search("q", source=:internetarchive, max_results=1)
            @test df.authors[1] == ["A","B"]
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

    @testset "Zenodo without DOI falls back to HTML" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("zenodo.org", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "hits" => Dict(
                        "hits" => [
                            Dict(
                                "id" => 222,
                                "links" => Dict("html" => "https://zenodo.org/record/222"),
                                "metadata" => Dict("title" => "No DOI")
                            )
                        ]
                    )
                )))
            end
            return HTTP.Response(404)
        end)
        try
            df = DataScout.search("q", source=:zenodo, max_results=1)
            @test df.url[1] == "https://zenodo.org/record/222"
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "DuckDuckGo Only RelatedTopics" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("api.duckduckgo.com", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "Heading" => "",
                    "AbstractURL" => "",
                    "Results" => Any[],
                    "RelatedTopics" => [
                        Dict("Text" => "T1", "FirstURL" => "u1"),
                        Dict("Text" => "T2", "FirstURL" => "u2")
                    ]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            df = DataScout.search("q", source=:duckduckgo, max_results=2)
            @test nrow(df) == 2
            @test all(df.source .== "DuckDuckGo")
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "SearxNG Result Limit Enforcement" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("/search?", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "results" => [
                        Dict("title" => "1", "url" => "u1"),
                        Dict("title" => "2", "url" => "u2"),
                        Dict("title" => "3", "url" => "u3")
                    ]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            df = DataScout.search("q", source=:searxng, max_results=2)
            @test nrow(df) == 2
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Open Library Missing Key URL Missing" begin
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("openlibrary.org", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "docs" => [Dict("title" => "No Key", "author_name" => ["A"]) ]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            df = DataScout.search("q", source=:openlibrary, max_results=1)
            @test ismissing(df.url[1])
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end
end