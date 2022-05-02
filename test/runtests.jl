using OpenCSV
using Test

const PSRI = OpenCSV.PSRClassesInterface

@testset "OpenCSV file format" begin
    @testset "Read and write with monthlydata" begin
        include("read_and_write_monthly.jl")
    end
    @testset "Read and write with hourlydata" begin
        include("read_and_write_hourly.jl")
    end
end