mutable struct Writer <: PSRI.AbstractWriter
    io::IOStream
    stages::Int
    scenarios::Int
    blocks::Int
    agents::Int
    isopen::Bool
    is_hourly::Bool
    path::String
    stage_type::PSRI.StageType
    initial_stage::Int
    initial_year::Int
    row_separator::String
    last_stage_registry::Int
    last_scenario_registry::Int
    last_block_registry::Int
end

PSRI.is_hourly(graf::Writer) = graf.is_hourly
PSRI.stage_type(graf::Writer) = graf.stage_type
PSRI.max_blocks(graf::Writer) = graf.blocks
PSRI.initial_stage(graf::Writer) = graf.initial_stage
PSRI.hour_discretization(graf::Writer) = 1

function _build_agents_str(agents::Vector{String})
    agents_str = ""
    for ag in agents
        agents_str *= ag * ','
    end
    agents_str = chop(agents_str; tail = 1)
    return agents_str
end

function PSRI.open(
    ::Type{Writer},
    path::String;
    # mandatory
    blocks::Integer = 0,
    scenarios::Integer = 0,
    stages::Integer = 0,
    agents::Vector{String} = String[],
    unit::Union{Nothing, String} = nothing,
    # optional
    is_hourly::Bool = false,
    name_length::Integer = 24,
    block_type::Integer = 1,
    scenarios_type::Integer = 1,
    stage_type::PSRI.StageType = PSRI.STAGE_MONTH,
    initial_stage::Integer = 1,
    initial_year::Integer = 1900,
    sequential_model::Bool = true,
    # addtional
    allow_unsafe_name_length::Bool = false,
    last_stage_registry::Int = 1,
    last_scenario_registry::Int = 1,
    last_block_registry::Int = 0,
)

    # TODO: consider name length
    if !allow_unsafe_name_length
        if name_length != 24 && name_length != 12
            error("name_length should be either 24 or 11. " *
                "To use a different value at your own risk enable: " *
                "allow_unsafe_name_length = true.")
        end
    end
    if !(0 <= block_type <= 3)
        error("block_type must be between 0 and 3, got $block_type")
    end
    if block_type == 0 && blocks != 1
        error("block_type = 0, requires blocks = 1, got blocks = $blocks")
    end
    if !(0 <= scenarios_type <= 1)
        error("scenarios_type must be between 0 and 1, got $scenarios_type")
    end
    if scenarios_type == 0 && scenarios != 1
        error("scenarios_type = 0, requires scenarios = 1, got scenarios = $scenarios")
    end
    if unit === nothing
        error("Please provide a unit string: unit = \"MW\"")
    end
    if !(0 < initial_stage <= PSRI.STAGES_IN_YEAR[stage_type])
        error("initial_stage must be between 1 and $(PSRI.STAGES_IN_YEAR[stage_type]) for $stage_type files, got: $initial_stage")
    end
    if !(0 < initial_year <= 1_000_000_000)
        error("initial_year must be a positive integer, got: $initial_year")
    end
    if is_hourly
        if block_type == 0
            error("Hourly files cannot have block_type == 0")
        end
        if 0 < blocks && verbose_hour_block_check
            println("Hourly files will ignore block dimension")
        end
    else
        if !(0 < blocks < 1_000_000)
            error("blocks must be a positive integer, got: $blocks")
        end
    end
    if !(0 < scenarios < 1_000_000_000)
        error("scenarios must be a positive integer, got: $scenarios")
    end
    if !(0 < stages < 1_000_000_000)
        error("stages must be a positive integer, got: $stages")
    end
    if isempty(agents)
        error("empty agents vector")
    end
    if !allunique(agents)
        error("agents must be unique.")
    end

    dir = dirname(path)
    if !isdir(dir)
        error("Directory $dir does not exist.")
    end

    if !isempty(splitext(path)[2])
        error("file path must be provided with no extension")
    end

    # delete previous file or error if its open
    PSRI._delete_or_error(path)

    # Inicia gravacao do resultado
    FILE_PATH = normpath(path)

    # agents with name_length
    agents_with_name_length = _build_agents_str(agents)
    # save header
    io = open(FILE_PATH * ".csv", "w")
    Base.write(io, "Varies per block?       ,$block_type,Unit,$unit,$(Integer(stage_type)),$initial_stage,$initial_year\r\n")
    Base.write(io, "Varies per sequence?    ,$scenarios_type\r\n")
    Base.write(io, "# of agents             ,$(length(agents))\r\n")
    Base.write(io, "Stag,Seq.,Blck,$agents_with_name_length\r\n")

    #Line breaker to be used
    row_separator = Sys.iswindows() ? "\r\n" : "\n"

    return Writer(
        io,
        stages,
        scenarios,
        blocks,
        length(agents),
        true,
        is_hourly,
        path,
        stage_type,
        initial_stage,
        initial_year,
        row_separator,
        last_stage_registry,
        last_scenario_registry,
        last_block_registry,
    )
end

function check_next_registry(
    writer::Writer,
    stage::Integer,
    scenario::Integer,
    block::Integer,
)
    blocks_in_stage = PSRI.blocks_in_stage(writer, writer.last_stage_registry)

    if writer.last_block_registry == blocks_in_stage
        expected_block = 1
        reset_block = true
    else
        expected_block = writer.last_block_registry + 1
        reset_block = false
    end

    if reset_block && writer.last_scenario_registry == writer.scenarios
        expected_scenario = 1
        reset_scenario = true
    elseif reset_block
        expected_scenario = writer.last_scenario_registry + 1
        reset_scenario = false
    else
        expected_scenario = writer.last_scenario_registry
        reset_scenario = false
    end

    if reset_scenario && reset_block
        expected_stage = writer.last_stage_registry + 1
        reset_stage = false
    else
        expected_stage = writer.last_stage_registry
        reset_stage = false
    end

    if (expected_stage == stage) && (expected_scenario == scenario) && (expected_block == block)
        return
    else
        error("In GrafCSV, registries must be written by iterating indexes in (stages, scenarios, blocks) order.\n 
               Last registry: (stage: $(writer.last_stage_registry), scenario: $(writer.last_scenario_registry), block: $(writer.last_block_registry)) \n
               Current registry: (stage: $(stage), scenario: $(scenario), block: $(block)) \n
               Expected registry: (stage: $(expected_stage), scenario: $(expected_scenario), block: $(expected_block)) \n
               To add registries in any order, use OpenBinary format.")
    end
    
end

function PSRI.write_registry(
    writer::Writer,
    data::Vector{Float64},
    stage::Integer,
    scenario::Integer = 1,
    block::Integer = 1,
) where T

    if !writer.isopen
        error("File is not in open state.")
    end

    if !(1 <= stage <= writer.stages)
        error("stage should be between 1 and $(io.stages)")
    end
    if !(1 <= scenario <= writer.scenarios)
        error("scenarios should be between 1 and $(writer.scenarios)")
    end
    if !(1 <= block <= PSRI.blocks_in_stage(writer, stage))
        error("block should be between 1 and $(writer.blocks)")
    end
    if length(data) != writer.agents
        error("data vector has length $(length(data)) and expected was $(writer.agents)")
    end

    check_next_registry(writer, stage, scenario, block)

    str = ""
    str *= string(stage) * ','
    str *= string(scenario) * ','
    str *= string(block) * ','
    for d in data
        str *= string(d) * ','
    end
    str = chop(str; tail = 1) # remove last comma
    str *= writer.row_separator
    Base.write(writer.io, str)

    writer.last_stage_registry = stage
    writer.last_scenario_registry = scenario
    writer.last_block_registry = block
    return nothing
end

"""

    close(writer::Writer)

Closes CSV file from `Writer` instance.
"""
function PSRI.close(writer::Writer)
    Base.close(writer.io)
    writer.isopen = false
    return nothing
end
