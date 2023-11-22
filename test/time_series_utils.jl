function rm_bin_hdr(file::String)
    rm(file * ".bin")
    rm(file * ".hdr")
    return nothing
end

function test_non_unique_agents()
    FILE_PATH = joinpath(".", "example_non_unique_agents")
    @test_throws ErrorException iow = PSRI.open(
        GrafCSV.Writer,
        FILE_PATH,
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

test_non_unique_agents()

function test_convert_twice()
    BLOCKS = 3
    SCENARIOS = 10
    STAGES = 12

    FILE_PATH = joinpath(".", "example_convert_1")
    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_PATH,
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = ["X", "Y", "Z"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
    )

    for estagio in 1:STAGES, serie in 1:SCENARIOS, bloco in 1:BLOCKS
        X = estagio + serie + 0.0
        Y = serie - estagio + 0.0
        Z = estagio + serie + bloco * 100.0
        PSRI.write_registry(
            iow,
            [X, Y, Z],
            estagio,
            serie,
            bloco,
        )
    end

    # Finaliza gravacao
    PSRI.close(iow)

    PSRI.convert_file(
        PSRI.OpenBinary.Reader,
        GrafCSV.Writer,
        FILE_PATH,
    )

    ior = PSRI.open(
        GrafCSV.Reader,
        FILE_PATH,
        use_header = false,
    )

    @test PSRI.max_stages(ior) == STAGES
    @test PSRI.max_scenarios(ior) == SCENARIOS
    @test PSRI.max_blocks(ior) == BLOCKS
    @test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
    @test PSRI.initial_stage(ior) == 1
    @test PSRI.initial_year(ior) == 2006
    @test PSRI.data_unit(ior) == "MW"

    # obtem número de colunas
    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for estagio in 1:STAGES
        for serie in 1:SCENARIOS
            for bloco in 1:BLOCKS
                @test PSRI.current_stage(ior) == estagio
                @test PSRI.current_scenario(ior) == serie
                @test PSRI.current_block(ior) == bloco

                X = estagio + serie
                Y = serie - estagio
                Z = estagio + serie + bloco * 100
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

    FILE_PATH_2 = joinpath(".", "example_convert_2")

    PSRI.convert_file(
        GrafCSV.Reader,
        PSRI.OpenBinary.Writer,
        FILE_PATH,
        path_to = FILE_PATH_2,
    )

    ior = PSRI.open(
        PSRI.OpenBinary.Reader,
        FILE_PATH_2,
        use_header = false,
    )

    @test PSRI.max_stages(ior) == STAGES
    @test PSRI.max_scenarios(ior) == SCENARIOS
    @test PSRI.max_blocks(ior) == BLOCKS
    @test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
    @test PSRI.initial_stage(ior) == 1
    @test PSRI.initial_year(ior) == 2006
    @test PSRI.data_unit(ior) == "MW"

    # obtem número de colunas
    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for estagio in 1:STAGES
        for serie in 1:SCENARIOS
            for bloco in 1:BLOCKS
                @test PSRI.current_stage(ior) == estagio
                @test PSRI.current_scenario(ior) == serie
                @test PSRI.current_block(ior) == bloco
                X = estagio + serie
                Y = serie - estagio
                Z = estagio + serie + bloco * 100
                ref = [X, Y, Z]
                for agent in 1:3
                    @test ior[agent] == ref[agent]
                end
                PSRI.next_registry(ior)
            end
        end
    end

    PSRI.close(ior)

    rm_bin_hdr(FILE_PATH)
    rm_bin_hdr(FILE_PATH_2)
    try
        rm(FILE_PATH * ".csv")
    catch
        println("Failed to remove $(FILE_PATH).csv")
    end

    return
end

test_convert_twice()

function test_file_to_array()
    BLOCKS = 3
    SCENARIOS = 10
    STAGES = 12

    FILE_PATH = joinpath(".", "example_array_1")
    iow = PSRI.open(
        PSRI.OpenBinary.Writer,
        FILE_PATH,
        blocks = BLOCKS,
        scenarios = SCENARIOS,
        stages = STAGES,
        agents = ["X", "Y", "Z"],
        unit = "MW",
        # optional:
        initial_stage = 1,
        initial_year = 2006,
    )

    for estagio in 1:STAGES, serie in 1:SCENARIOS, bloco in 1:BLOCKS
        X = estagio + serie + 0.0
        Y = serie - estagio + 0.0
        Z = estagio + serie + bloco * 100.0
        PSRI.write_registry(
            iow,
            [X, Y, Z],
            estagio,
            serie,
            bloco,
        )
    end

    PSRI.close(iow)

    data, header = PSRI.file_to_array_and_header(
        PSRI.OpenBinary.Reader,
        FILE_PATH;
        use_header = false,
    )

    data_order, header_order = PSRI.file_to_array_and_header(
        PSRI.OpenBinary.Reader,
        FILE_PATH;
        use_header = true,
        header = ["Y", "Z", "X"],
    )

    @test data == PSRI.file_to_array(
        PSRI.OpenBinary.Reader,
        FILE_PATH;
        use_header = false,
    )

    @test data_order == PSRI.file_to_array(
        PSRI.OpenBinary.Reader,
        FILE_PATH;
        use_header = true,
        header = ["Y", "Z", "X"],
    )

    @test data_order[1] == data[2] # "Y"
    @test data_order[2] == data[3] # "Z"
    @test data_order[3] == data[1] # "X"

    PSRI.array_to_file(
        GrafCSV.Writer,
        FILE_PATH,
        data,
        agents = header,
        unit = "MW",
        initial_year = 2006,
    )

    ior = PSRI.open(
        GrafCSV.Reader,
        FILE_PATH,
        use_header = false,
    )

    @test PSRI.max_stages(ior) == STAGES
    @test PSRI.max_scenarios(ior) == SCENARIOS
    @test PSRI.max_blocks(ior) == BLOCKS
    @test PSRI.stage_type(ior) == PSRI.STAGE_MONTH
    @test PSRI.initial_stage(ior) == 1
    @test PSRI.initial_year(ior) == 2006
    @test PSRI.data_unit(ior) == "MW"

    # obtem número de colunas
    @test PSRI.agent_names(ior) == ["X", "Y", "Z"]

    for estagio in 1:STAGES
        for serie in 1:SCENARIOS
            for bloco in 1:BLOCKS
                @test PSRI.current_stage(ior) == estagio
                @test PSRI.current_scenario(ior) == serie
                @test PSRI.current_block(ior) == bloco

                X = estagio + serie
                Y = serie - estagio
                Z = estagio + serie + bloco * 100
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

    rm_bin_hdr(FILE_PATH)
    try
        rm(FILE_PATH * ".csv")
    catch
        println("Failed to remove $(FILE_PATH).csv")
    end

    return
end

test_file_to_array()
