function test_read_and_write_hourly()
    FILE_GERTER = joinpath(".", "data", "gerter")

    STAGES = 3
    SCENARIOS = 2
    AGENTS = ["X", "Y", "Z"]
    UNIT = "MW"
    STAGE_TYPE = PSRI.STAGE_MONTH
    INITIAL_STAGE = 2
    INITIAL_YEAR = 2006

    gerter = PSRI.open(
        GrafCSV.Writer,
        FILE_GERTER,
        is_hourly = true,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = AGENTS,
        unit = UNIT,
        # optional:
        stage_type = STAGE_TYPE,
        initial_stage = INITIAL_STAGE,
        initial_year = INITIAL_YEAR,
    )

    # Loop de gravacao
    for stage in 1:STAGES
        for scenario in 1:SCENARIOS
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

    # Finaliza gravacao
    PSRI.close(gerter)

    ior = PSRI.open(
        GrafCSV.Reader,
        FILE_GERTER,
        is_hourly = true,
    )

    @test PSRI.max_stages(ior) == STAGES
    @test PSRI.max_scenarios(ior) == SCENARIOS
    @test PSRI.max_blocks(ior) == 744
    @test PSRI.stage_type(ior) == STAGE_TYPE
    @test PSRI.initial_stage(ior) == INITIAL_STAGE
    @test PSRI.initial_year(ior) == INITIAL_YEAR
    @test PSRI.data_unit(ior) == UNIT
    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for stage in 1:STAGES
        for scenario in 1:SCENARIOS
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

    try
        rm(FILE_GERTER * ".csv")
    catch
    end

    return nothing
end