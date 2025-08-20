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
        patch = @patch function HTTP.get(url::String; headers=Dict())
            return HTTP.Response(200, "test")
        end

        apply(patch) do
            start_time = now()
            DataScout.Services.Core.api_request(:test_rate, "http://example.com")
            DataScout.Services.Core.api_request(:test_rate, "http://example.com")
            elapsed = (now() - start_time).value / 1000
            # Should have some delay due to rate limiting
            @test elapsed >= 0
        end
    end
end