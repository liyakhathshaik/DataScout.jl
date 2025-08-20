using Mocking
Mocking.activate()
using DataScout
using Test

@testset "DataScout Tests" begin
    include("config_tests.jl")
    include("service_tests.jl")
    include("normalize_tests.jl")
    include("core_tests.jl")
end