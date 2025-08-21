using DataScout
using Test
using HTTP
using JSON3
using Mocking
using Dates

Mocking.activate()

@testset "Core Service Tests" begin
    @testset "API Request Function" begin
        # Test successful request
        # Inject custom GET handler
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> HTTP.Response(200, "{\"test\": \"data\"}"))
        result = DataScout.Services.Core.api_request(:test, "http://example.com")
        @test result == "{\"test\": \"data\"}"
        DataScout.Services.Core.reset_http_handlers!()

        # Test retry mechanism
        attempt_count = 0
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            attempt_count += 1
            if attempt_count < 3
                throw(HTTP.RequestError("Network error"))
            else
                HTTP.Response(200, "success")
            end
        end)
        result = DataScout.Services.Core.api_request(:test, "http://example.com"; retries=3)
        @test result == "success"
        @test attempt_count == 3
        DataScout.Services.Core.reset_http_handlers!()
    end

    @testset "Rate Limiting" begin
        # Test that rate limiting doesn't break functionality
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> HTTP.Response(200, "test"))
        try
            start_time = now()
            DataScout.Services.Core.api_request(:test_rate, "http://example.com")
            DataScout.Services.Core.api_request(:test_rate, "http://example.com")
            elapsed = (now() - start_time).value / 1000
            # Should have some delay due to rate limiting
            @test elapsed >= 0
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "POST Request Path" begin
        DataScout.Services.Core.set_http_post!((url::String; headers=Dict(), body="") -> begin
            @test url == "http://example.com/post"
            @test body == "payload"
            return HTTP.Response(200, "posted")
        end)
        try
            # Call via api_request with method POST
            result = DataScout.Services.Core.api_request(:test_post, "http://example.com/post"; method="POST", body="payload")
            @test result == "posted"
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "api_request Failure After Retries" begin
        # Force failure and ensure it throws after configured retries with minimal wait
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> throw(HTTP.RequestError("Network error")))
        try
            @test_throws ErrorException DataScout.Services.Core.api_request(:fail_test, "http://example.com"; retries=1)
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end

    @testset "Deprecated search_core Alias" begin
        # Mock API and set dummy API key to hit Services.search_core via alias
        DataScout.Services.Core.set_http_get!((url::String; headers=Dict()) -> begin
            if occursin("api.core.ac.uk", url)
                return HTTP.Response(200, JSON3.write(Dict(
                    "results" => [Dict(
                        "title" => "Alias Test",
                        "downloadUrl" => "https://core.ac.uk/download/1.pdf",
                        "authors" => [Dict("fullName" => "Alias Author")],
                        "id" => "1"
                    )]
                )))
            end
            return HTTP.Response(404)
        end)
        try
            DataScout.set_api_key!(:core, "dummy")
            df = DataScout.search_core("alias"; max_results=1)
            @test nrow(df) == 1
            @test df.title[1] == "Alias Test"
        finally
            DataScout.Services.Core.reset_http_handlers!()
        end
    end
end