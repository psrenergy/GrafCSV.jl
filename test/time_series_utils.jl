function test_non_unique_agents()
    path = joinpath(".", "data", "example_non_unique_agents")
    @test_throws ErrorException iow = PSRI.open(
        GrafCSV.Writer,
        path,
        blocks = 3,
        scenarios = 4,
        stages = 5,
        agents = ["X", "Y", "X"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
    )
end

function test_convert_twice()
    path1 = joinpath(".", "data", "convert_1")
    path2 = joinpath(".", "data", "convert_2")

    blocks = 3
    scenarios = 10
    stages = 12

    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        path1,
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = ["X", "Y", "Z"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
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

    PSRI.convert_file(
        PSRI.OpenBinary.Reader,
        GrafCSV.Writer,
        path1,
    )

    ior = PSRI.open(
        GrafCSV.Reader,
        path1,
        use_header = false,
    )

    @test PSRI.max_stages(ior) == stages
    @test PSRI.max_scenarios(ior) == scenarios
    @test PSRI.max_blocks(ior) == blocks
    @test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
    @test PSRI.initial_stage(ior) == 1
    @test PSRI.initial_year(ior) == 2006
    @test PSRI.data_unit(ior) == "MW"

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
    ior = nothing

    PSRI.convert_file(
        GrafCSV.Reader,
        PSRI.OpenBinary.Writer,
        path1,
        path_to = path2,
    )

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        path2,
        use_header = false,
    )

    @test PSRI.max_stages(ior) == stages
    @test PSRI.max_scenarios(ior) == scenarios
    @test PSRI.max_blocks(ior) == blocks
    @test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
    @test PSRI.initial_stage(ior) == 1
    @test PSRI.initial_year(ior) == 2006
    @test PSRI.data_unit(ior) == "MW"

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

    safe_remove("$path1.bin")
    safe_remove("$path1.hdr")

    safe_remove("$path2.bin")
    safe_remove("$path2.hdr")
    
    safe_remove("$path1.csv")

    return nothing
end

function test_file_to_array()
    blocks = 3
    scenarios = 10
    stages = 12

    path = joinpath(".", "data", "example_array_1")
    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        path,
        blocks = blocks,
        scenarios = scenarios,
        stages = stages,
        agents = ["X", "Y", "Z"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
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

    data, header = PSRI.file_to_array_and_header(
        PSRI.OpenBinary.Reader,
        path;
        use_header = false,
    )

    data_order, header_order = PSRI.file_to_array_and_header(
        PSRI.OpenBinary.Reader,
        path;
        use_header = true,
        header = ["Y", "Z", "X"],
    )

    @test data == PSRI.file_to_array(
        PSRI.OpenBinary.Reader,
        path;
        use_header = false,
    )

    @test data_order == PSRI.file_to_array(
        PSRI.OpenBinary.Reader,
        path;
        use_header = true,
        header = ["Y", "Z", "X"],
    )

    @test data_order[1] == data[2] # "Y"
    @test data_order[2] == data[3] # "Z"
    @test data_order[3] == data[1] # "X"

    PSRI.array_to_file(
        GrafCSV.Writer,
        path,
        data,
        agents = header,
        unit = "MW",
        initial_year = 2006,
    )

    ior = PSRI.open(
        GrafCSV.Reader,
        path,
        use_header = false,
    )

    @test PSRI.max_stages(ior) == stages
    @test PSRI.max_scenarios(ior) == scenarios
    @test PSRI.max_blocks(ior) == blocks
    @test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
    @test PSRI.initial_stage(ior) == 1
    @test PSRI.initial_year(ior) == 2006
    @test PSRI.data_unit(ior) == "MW"

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
    ior = nothing

    safe_remove("$path.bin")
    safe_remove("$path.hdr")
    safe_remove("$path.csv")

    return nothing
end

function test_time_series_utils()
    test_non_unique_agents()
    test_convert_twice()
    test_file_to_array()
    return nothing
end
