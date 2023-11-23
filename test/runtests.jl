using GrafCSV
using Test

const PSRI = GrafCSV.PSRClassesInterface

include("utils.jl")
include("read_and_write_monthly.jl")
include("read_and_write_hourly.jl")
include("time_series_utils.jl")
include("issues.jl")

function test_all()
    @testset "Read and write with monthly data" begin test_read_and_write_monthly() end
    @testset "Read and write with hourly data" begin test_read_and_write_hourly() end
    @testset "Utils" begin test_time_series_utils() end
    @testset "Issues" begin test_issues() end
end

test_all()
