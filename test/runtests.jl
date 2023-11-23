using GrafCSV
using Test

const PSRI = GrafCSV.PSRClassesInterface

include("read_and_write_monthly.jl")
include("read_and_write_hourly.jl")
include("time_series_utils.jl")

@testset "GrafCSV file format" begin
    @testset "Read and write with monthly data" test_read_and_write_monthly()
    @testset "Read and write with hourly data" test_read_and_write_hourly()
    @testset "Utils" test_time_series_utils()
end
