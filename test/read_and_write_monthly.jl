function test_read_and_write_monthly()
    path = joinpath(".", "data", "monthly")

    stages = 12
    blocks = 3
    scenarios = 4
    stage_type = PSRI.STAGE_MONTH
    initial_stage = 1
    initial_year = 2006
    unit = "MW"

    iow = PSRI.open(
        GrafCSV.Writer,
        path,
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = ["X", "Y", "Z"],
        unit = unit,
        # optional:
        stage_type = stage_type,
        initial_stage = initial_stage,
        initial_year = initial_year,
    )

    for stage in 1:stages, scenario in 1:scenarios, block in 1:blocks
        X = stage + scenario + 0.0
        Y = scenario - stage + 0.0
        Z = stage + scenario + block * 100.0
        PSRI.write_registry(
            iow,
            [X, Y, Z],
            stage,
            scenario,
            block,
        )
    end

    PSRI.close(iow)

    ior = PSRI.open(
        GrafCSV.Reader,
        path,
    )

    @test PSRI.max_stages(ior) == stages
    @test PSRI.max_scenarios(ior) == scenarios
    @test PSRI.max_blocks(ior) == blocks
    @test PSRI.stage_type(ior) == stage_type
    @test PSRI.initial_stage(ior) == initial_stage
    @test PSRI.initial_year(ior) == initial_year
    @test PSRI.data_unit(ior) == unit

    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for stage in 1:stages
        for scenario in 1:scenarios
            for block in 1:blocks
                @test PSRI.current_stage(ior) == stage
                @test PSRI.current_scenario(ior) == scenario
                @test PSRI.current_block(ior) == block

                X = stage + scenario
                Y = scenario - stage
                Z = stage + scenario + block * 100
                ref = [X, Y, Z]

                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end
                PSRI.next_registry(ior)
            end
        end
    end

    PSRI.close(ior)

    @test_throws ErrorException PSRI.convert_file(
        GrafCSV.Reader,
        GrafCSV.Writer,
        path,
    )

    ior = nothing

    safe_remove(path * ".csv")

    return nothing
end
