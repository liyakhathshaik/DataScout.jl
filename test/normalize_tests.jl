using DataScout
using Test
using DataFrames

@testset "Normalization Tests" begin
    @testset "dict_to_dataframe Function" begin
        # Test empty input
        empty_df = DataScout.Normalize.dict_to_dataframe(Dict{String,Any}[])
        @test nrow(empty_df) == 0
        @test ncol(empty_df) == 5
        @test names(empty_df) == ["title", "url", "authors", "source", "id"]

        # Test single record
        single_record = [Dict(
            "title" => "Test Title",
            "url" => "https://example.com",
            "authors" => ["Author 1", "Author 2"],
            "source" => "Test Source",
            "id" => "test_id_123"
        )]
        
        df_single = DataScout.Normalize.dict_to_dataframe(single_record)
        @test nrow(df_single) == 1
        @test df_single.title[1] == "Test Title"
        @test df_single.url[1] == "https://example.com"
        @test df_single.authors[1] == ["Author 1", "Author 2"]
        @test df_single.source[1] == "Test Source"
        @test df_single.id[1] == "test_id_123"

        # Test missing values
        missing_values = [Dict(
            "title" => missing,
            "url" => missing,
            "authors" => missing,
            "source" => missing,
            "id" => missing
        )]
        
        df_missing = DataScout.Normalize.dict_to_dataframe(missing_values)
        @test nrow(df_missing) == 1
        @test ismissing(df_missing.title[1])
        @test ismissing(df_missing.url[1])
        @test ismissing(df_missing.authors[1])
        @test ismissing(df_missing.source[1])
        @test ismissing(df_missing.id[1])

        # Test numeric ID conversion
        numeric_id = [Dict(
            "title" => "Test",
            "url" => "https://example.com",
            "authors" => ["Author"],
            "source" => "Test",
            "id" => 12345
        )]
        
        df_numeric = DataScout.Normalize.dict_to_dataframe(numeric_id)
        @test df_numeric.id[1] == "12345"
    end

    @testset "handle_authors Function" begin
        # Test vector input
        @test DataScout.Normalize.handle_authors(["Author 1", "Author 2"]) == ["Author 1", "Author 2"]
        
        # Test empty vector
        @test ismissing(DataScout.Normalize.handle_authors(String[]))
        
        # Test string input
        @test DataScout.Normalize.handle_authors("Single Author") == ["Single Author"]
        
        # Test missing input
        @test ismissing(DataScout.Normalize.handle_authors(missing))
    end
end