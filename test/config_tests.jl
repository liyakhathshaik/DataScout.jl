using DataScout
using Test
using TOML

@testset "Configuration System" begin
    @testset "Config File Operations" begin
        # Test config file exists
        @test isfile(DataScout.Config.CONFIG_PATH)
        
        # Test config directory exists
        @test isdir(DataScout.Config.CONFIG_DIR)
    end
    
    @testset "API Key Management" begin
        # Test getting non-existent API key
        @test DataScout.Config.get_api_key(:nonexistent) === nothing
        
        # Test setting and getting API key
        DataScout.Config.set_api_key!(:test_service, "test_key_123")
        @test DataScout.Config.get_api_key(:test_service) == "test_key_123"
        
        # Test overwriting API key
        DataScout.Config.set_api_key!(:test_service, "new_test_key")
        @test DataScout.Config.get_api_key(:test_service) == "new_test_key"
        
        # Test convenience functions
        DataScout.set_api_key!(:another_test, "another_key")
        @test DataScout.get_api_key(:another_test) == "another_key"
    end
    
    @testset "Rate Limiting Configuration" begin
        # Test default rate limit for core
        @test DataScout.Config.get_rate_limit(:core) == 0.3
        
        # Test default rate limit for unknown service
        @test DataScout.Config.get_rate_limit(:unknown_service) == 0.5
        
        # Test rate limit is positive
        @test DataScout.Config.get_rate_limit(:core) > 0
    end
    
    @testset "Config File Format" begin
        # Test that config file can be parsed
        config = DataScout.Config.get_config()
        @test haskey(config, "api_keys")
        @test haskey(config, "rate_limits")
        @test config["rate_limits"]["core"] == 0.3
    end
end