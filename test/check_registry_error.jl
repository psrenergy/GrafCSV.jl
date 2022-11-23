function check_registry_error_test()
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
        initial_year = INITIAL_YEAR
    )

    # ---------------------------------------------
    # Parte 3 - Gravacao dos registros do resultado
    # ---------------------------------------------

    stage, scenario, block = 1, 1, 1
    X = stage + scenario + 0.
    Y = scenario - stage + 0.
    Z = stage + scenario + block * 100.
    PSRI.write_registry(
            iow,
            [X, Y, Z],
            stage,
            scenario,
            block
        )

    stage, scenario, block = 1, 2, 1
    X = stage + scenario + 0.
    Y = scenario - stage + 0.
    Z = stage + scenario + block * 100.
    @test_throws ErrorException PSRI.write_registry(
        iow,
        [X, Y, Z],
        stage,
        scenario,
        block
    )

    # Finaliza gravacao
    PSRI.close(iow)
end
check_registry_error_test()