function issue13()
    path = joinpath(".", "data", "businj")

    ior = PSRI.open(
        GrafCSV.Reader,
        path,
    )
end

function test_issues()
    @testset "Issue 13" begin issue13() end
end

test_issues()