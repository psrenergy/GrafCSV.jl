function test_read_and_write_hourly()
    path = joinpath(".", "data", "hourly")

    stages = 3
    scenarios = 2
    AGENTS = ["X", "Y", "Z"]
    unit = "MW"
    stage_type = PSRI.STAGE_MONTH
    initial_stage = 2
    initial_year = 2006

    gerter = PSRI.open(
        GrafCSV.Writer,
        path,
        is_hourly = true,
        scenarios = scenarios,
        stages = stages,
        agents = AGENTS,
        unit = unit,
        # optional:
        stage_type = stage_type,
        initial_stage = initial_stage,
        initial_year = initial_year,
    )

    for stage in 1:stages
        for scenario in 1:scenarios
            for block in 1:PSRI.blocks_in_stage(gerter, stage)
                X = 10_000.0 * stage + 1000.0 * scenario + block
                Y = block + 0.0
                Z = 10.0 * stage + scenario
                PSRI.write_registry(
                    gerter,
                    [X, Y, Z],
                    stage,
                    scenario,
                    block,
                )
            end
        end
    end

    PSRI.close(gerter)

    ior = PSRI.open(
        GrafCSV.Reader,
        path,
        is_hourly = true,
    )

    @test PSRI.max_stages(ior) == stages
    @test PSRI.max_scenarios(ior) == scenarios
    @test PSRI.max_blocks(ior) == 744
    @test PSRI.stage_type(ior) == stage_type
    @test PSRI.initial_stage(ior) == initial_stage
    @test PSRI.initial_year(ior) == initial_year
    @test PSRI.data_unit(ior) == unit
    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for stage in 1:stages
        for scenario in 1:scenarios
            for block in 1:PSRI.blocks_in_stage(ior, stage)
                @test PSRI.current_stage(ior) == stage
                @test PSRI.current_scenario(ior) == scenario
                @test PSRI.current_block(ior) == block

                X = 10_000.0 * stage + 1000.0 * scenario + block
                Y = block + 0.0
                Z = 10.0 * stage + scenario
                ref = [X, Y, Z]

                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end

                PSRI.next_registry(ior)
            end
        end
    end

    PSRI.close(ior)
    ior = nothing
    GC.gc()
    GC.gc()

    safe_remove(path * ".csv")

    return nothing
end
