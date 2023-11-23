function read_write_csv_test()
    FILE_PATH = joinpath(".", "example_2")

    STAGES = 12
    BLOCKS = 3
    SCENARIOS = 4
    STAGE_TYPE = PSRI.STAGE_MONTH
    INITIAL_STAGE = 1
    INITIAL_YEAR = 2006
    UNIT = "MW"

    iow = PSRI.open(
        GrafCSV.Writer,
        FILE_PATH,
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = ["X", "Y", "Z"],
        unit = UNIT,
        # optional:
        stage_type = STAGE_TYPE,
        initial_stage = INITIAL_STAGE,
        initial_year = INITIAL_YEAR,
    )

    # ---------------------------------------------
    # Parte 3 - Gravacao dos registros do resultado
    # ---------------------------------------------

    # Loop de gravacao
    for stage in 1:STAGES, scenario in 1:SCENARIOS, block in 1:BLOCKS
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

    # Finaliza gravacao
    PSRI.close(iow)

    ior = PSRI.open(
        GrafCSV.Reader,
        FILE_PATH,
    )

    @test PSRI.max_stages(ior) == STAGES
    @test PSRI.max_scenarios(ior) == SCENARIOS
    @test PSRI.max_blocks(ior) == BLOCKS
    @test PSRI.stage_type(ior) == STAGE_TYPE
    @test PSRI.initial_stage(ior) == INITIAL_STAGE
    @test PSRI.initial_year(ior) == INITIAL_YEAR
    @test PSRI.data_unit(ior) == UNIT

    # obtem número de colunas
    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for stage in 1:STAGES
        for scenario in 1:SCENARIOS
            for block in 1:BLOCKS
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
        FILE_PATH,
    )

    ior = nothing

    try
        rm(FILE_PATH * ".csv")
    catch
        println("Failed to delete: $FILE_PATH")
    end
end
read_write_csv_test()
