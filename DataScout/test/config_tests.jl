using DataScout
using Test

@testset "Configuration System" begin
    # Test config file exists
    @test isfile(DataScout.Config.CONFIG_PATH)
    
    # Test API key functions
    @test DataScout.Config.get_api_key(:core) isa Union{String,Nothing}
    
    # Test rate limits
    @test DataScout.Config.get_rate_limit(:core) > 0
end