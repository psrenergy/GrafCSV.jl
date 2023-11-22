module GrafCSV

import PSRClassesInterface
# Load packages defined in the upper module PSRClassesInterface
import Dates
import CSV

const PSRI = PSRClassesInterface

include("reader.jl")
include("writer.jl")

function PSRI.convert_file(
    ::Type{Reader},
    ::Type{Writer},
    path_from::AbstractString;
    path_to::AbstractString = "",
)
    error("Conversion with GrafCSV.Reader and GrafCSV.Writer is a no op.")
end

end