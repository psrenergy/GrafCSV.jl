using GrafCSV
using Test

const PSRI = GrafCSV.PSRClassesInterface

@testset "GrafCSV file format" begin
    @testset "Read and write with monthlydata" begin
        include("read_and_write_monthly.jl")
    end
    @testset "Read and write with hourlydata" begin
        include("read_and_write_hourly.jl")
    end
    @testset "Utils" begin
        include("time_series_utils.jl")
    end
end
