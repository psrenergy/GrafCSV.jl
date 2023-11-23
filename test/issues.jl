function issue13()
    path = joinpath(".", "data", "businj")

    reader = PSRI.open(
        GrafCSV.Reader,
        path,
    )

    @test PSRI.data_unit(reader) == "MW"
    @test PSRI.stage_type(reader) == PSRI.STAGE_MONTH
    @test PSRI.initial_stage(reader) == 1
    @test PSRI.initial_year(reader) == 2003

    @test PSRI.max_agents(reader) == 3
    @test length(PSRI.agent_names(reader)[1]) == 7
    @test length(PSRI.agent_names(reader)[2]) == 7
    @test length(PSRI.agent_names(reader)[3]) == 7
end

function test_issues()
    @testset "Issue 13" begin issue13() end
end