function safe_remove(path::AbstractString)
    try
        rm(path)
    catch
        println("Failed to remove $path")
    end
end
