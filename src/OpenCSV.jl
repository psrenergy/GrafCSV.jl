module OpenCSV

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
    path_from::String;
    path_to::String = "",
)
    error("Conversion with OpenCSV.Reader and OpenCSV.Writer is a no op.")
end

end