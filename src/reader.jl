mutable struct Reader <: PSRI.AbstractReader
    rows_iterator::CSV.Rows
    current_row::CSV.Row2
    current_row_state::Tuple{<:Integer, <:Integer, <:Integer}

    stages::Int
    scenarios::Int
    blocks::Int
    unit::String
    initial_stage::Int
    initial_year::Int

    current_stage::Int
    current_scenario::Int
    current_block::Int

    agent_names::Vector{String}
    num_agents::Int
    data::Vector{Float64}

    stage_type::PSRI.StageType
    is_hourly::Bool
end

function _parse_agents(row::AbstractVector{Symbol})
    return strip.(string.(row)[4:end])
end

function _parse_unit(header::AbstractVector{<:AbstractString})
    first_line_splitted = split(header[1], ',')
    return strip(first_line_splitted[4])
end

function _parse_stage_type(header::AbstractVector{<:AbstractString})
    first_line_splitted = split(header[1], ',')
    return PSRI.StageType(parse(Int, first_line_splitted[5]))
end

function _parse_initial_stage(header::AbstractVector{<:AbstractString})
    first_line_splitted = split(header[1], ',')
    return parse(Int, first_line_splitted[6])
end

function _parse_initial_year(header::AbstractVector{<:AbstractString})
    first_line_splitted = split(header[1], ',')
    return parse(Int, first_line_splitted[7])
end

function _parse_stages(last_line::AbstractString)
    last_line_splitted = split(last_line, ',')
    return parse(Int, last_line_splitted[1])
end

function _parse_scenarios(last_line::AbstractString)
    last_line_splitted = split(last_line, ',')
    return parse(Int, last_line_splitted[2])
end

function _parse_blocks(last_line::AbstractString, stages::Integer, is_hourly::Bool, stage_type::PSRI.StageType, initial_stage::Integer)
    if is_hourly
        if stage_type == PSRI.STAGE_MONTH
            blocks = 0
            for t in initial_stage:initial_stage+stages
                blocks_month = PSRI.DAYS_IN_MONTH[mod1(t - 1 + initial_stage, 12)] * 24
                if blocks_month > blocks
                    blocks = blocks_month
                end
            end
            return blocks
        else
            return PSRI.HOURS_IN_STAGE[stage_type]
            # error("Unknown stage_type = $(io.stage_type)")
        end
    end

    last_line_splitted = split(last_line, ',')
    return parse(Int, last_line_splitted[3])
end

function _read_last_line(file::AbstractString)
    open(file) do io
        seekend(io)
        seek(io, position(io) - 2)
        while Char(peek(io)) != '\n'
            seek(io, position(io) - 1)
        end
        Base.read(io, Char)
        return Base.read(io, String)
    end
end

function PSRI.open(
    ::Type{Reader},
    path::AbstractString;
    is_hourly::Bool = false,
    header::AbstractVector{<:AbstractString} = String[],
    use_header::Bool = false, # default to true
    allow_empty::Bool = false,
    first_stage::Dates.Date = Dates.Date(1900, 1, 1),
    verbose_header::Bool = false,
)
    # TODO
    if verbose_header || !isempty(header) || use_header || allow_empty
        error("verbose_header, header, use_header and allow_empty arguments not supported by GrafCSV")
    end

    if first_stage != Dates.Date(1900, 1, 1)
        error("first_stage not supported by GrafCSV")
    end

    PATH_CSV = path
    if !endswith(path, ".csv")
        PATH_CSV *= ".csv"
    end

    if !isfile(PATH_CSV)
        error("file not found: $PATH_CSV")
    end

    rows_iterator = CSV.Rows(PATH_CSV; header = 4)
    agent_names = _parse_agents(rows_iterator.names)
    num_agents = length(agent_names)
    current_row, current_row_state = iterate(rows_iterator)

    data = Vector{Float64}(undef, num_agents)
    for i in 1:num_agents
        data[i] = parse(Float64, current_row[i+3])
    end

    header = readuntil(PATH_CSV, "Stag") |> x -> split(x, "\n")
    unit = _parse_unit(header)
    stage_type = _parse_stage_type(header)
    initial_stage = _parse_initial_stage(header)
    initial_year = _parse_initial_year(header)
    last_line = _read_last_line(PATH_CSV)
    stages = _parse_stages(last_line)
    scenarios = _parse_scenarios(last_line)
    blocks = _parse_blocks(last_line, stages, is_hourly, stage_type, initial_stage)

    io = Reader(
        rows_iterator,
        current_row,
        (current_row_state),
        stages,
        scenarios,
        blocks,
        unit,
        initial_stage,
        initial_year,
        1,
        1,
        1,
        agent_names,
        num_agents,
        data,
        stage_type,
        is_hourly,
    )

    return io
end

function Base.getindex(reader::Reader, args...)
    return Base.getindex(reader.data, args...)
end

function PSRI.next_registry(ocr::Reader)
    next = iterate(ocr.rows_iterator, ocr.current_row_state)
    if next === nothing
        return nothing
    end
    ocr.current_row, ocr.current_row_state = next
    for i in 1:ocr.num_agents
        ocr.data[i] = parse(Float64, ocr.current_row[i+3])
    end
    ocr.current_stage = parse(Int64, ocr.current_row[1])
    ocr.current_scenario = parse(Int64, ocr.current_row[2])
    ocr.current_block = parse(Int64, ocr.current_row[3])
    return nothing
end

PSRI.max_stages(reader::Reader) = reader.stages
PSRI.max_scenarios(reader::Reader) = reader.scenarios
PSRI.max_blocks(reader::Reader) = reader.blocks
PSRI.max_agents(reader::Reader) = length(reader.agent_names)

PSRI.initial_stage(reader::Reader) = reader.initial_stage
PSRI.initial_year(reader::Reader) = reader.initial_year

PSRI.data_unit(reader::Reader) = reader.unit

PSRI.current_stage(reader::Reader) = reader.current_stage
PSRI.current_scenario(reader::Reader) = reader.current_scenario
PSRI.current_block(reader::Reader) = reader.current_block
PSRI.stage_type(reader::Reader) = reader.stage_type
PSRI.is_hourly(reader::Reader) = reader.is_hourly

PSRI.hour_discretization(graf::Reader) = 1

function PSRI.agent_names(reader::Reader)
    return reader.agent_names
end

function PSRI.close(reader::Reader)
    return nothing
end
