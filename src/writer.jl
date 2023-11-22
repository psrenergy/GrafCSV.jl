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
end

PSRI.is_hourly(graf::Writer) = graf.is_hourly
PSRI.stage_type(graf::Writer) = graf.stage_type
PSRI.max_blocks(graf::Writer) = graf.blocks
PSRI.initial_stage(graf::Writer) = graf.initial_stage
PSRI.hour_discretization(graf::Writer) = 1

function _build_agents_str(agents::AbstractVector{<:AbstractString})
    string = ""
    for agent in agents
        string *= agent * ','
    end
    string = chop(string; tail = 1)
    return string
end

function PSRI.open(
    ::Type{Writer},
    path::AbstractString;
    # mandatory
    blocks::Integer = 0,
    scenarios::Integer = 0,
    stages::Integer = 0,
    agents::AbstractVector{<:AbstractString} = String[],
    unit::Union{Nothing, <:AbstractString} = nothing,
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
    verbose_hour_block_check::Bool = true,
)
    # TODO: consider name length
    if !allow_unsafe_name_length
        if name_length != 24 && name_length != 12
            error(
                "Name length should be either 24 or 11. " *
                "To use a different value at your own risk enable: " *
                "allow_unsafe_name_length = true.",
            )
        end
    end

    if !(0 <= block_type <= 3)
        error("Block type must be between 0 and 3, got $block_type")
    end

    if block_type == 0 && blocks != 1
        error("Block type = 0, requires blocks = 1, got blocks = $blocks")
    end

    if !(0 <= scenarios_type <= 1)
        error("Scenarios type must be between 0 and 1, got $scenarios_type")
    end

    if scenarios_type == 0 && scenarios != 1
        error("Scenarios type = 0, requires scenarios = 1, got scenarios = $scenarios")
    end

    if unit === nothing
        error("Please provide a unit string: unit = \"MW\"")
    end

    if !(0 < initial_stage <= PSRI.STAGES_IN_YEAR[stage_type])
        error("Initial stage must be between 1 and $(PSRI.STAGES_IN_YEAR[stage_type]) for $stage_type files, got: $initial_stage")
    end

    if !(0 < initial_year <= 1_000_000_000)
        error("Initial year must be a positive integer, got: $initial_year")
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
            error("Blocks must be a positive integer, got: $blocks")
        end
    end

    if !(0 < scenarios < 1_000_000_000)
        error("Scenarios must be a positive integer, got: $scenarios")
    end

    if !(0 < stages < 1_000_000_000)
        error("Stages must be a positive integer, got: $stages")
    end

    if isempty(agents)
        error("Empty agents vector")
    end

    if !allunique(agents)
        error("Agents must be unique.")
    end

    dir = dirname(path)
    if !isdir(dir)
        error("Directory $dir does not exist.")
    end

    if !isempty(splitext(path)[2])
        error("File path must be provided with no extension")
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
    )
end

# TODO check next entry is in the correct order

function PSRI.write_registry(
    writer::Writer,
    data::AbstractVector{<:Real},
    stage::Integer,
    scenario::Integer = 1,
    block::Integer = 1,
)
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
