using DataScout
using Test

@testset "DataScout Tests" begin
    include("config_tests.jl")
    include("service_tests.jl")
end