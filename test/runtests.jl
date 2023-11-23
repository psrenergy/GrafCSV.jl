using GrafCSV
using Test

const PSRI = GrafCSV.PSRClassesInterface

include("read_and_write_monthly.jl")
include("read_and_write_hourly.jl")
include("time_series_utils.jl")

function test_all()
    @testset "Read and write with monthly data" begin test_read_and_write_monthly() end
    @testset "Read and write with hourly data" begin test_read_and_write_hourly() end
    @testset "Utils" begin test_time_series_utils() end
end

test_all()