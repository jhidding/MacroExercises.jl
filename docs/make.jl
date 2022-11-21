push!(LOAD_PATH,"../src/")

using Documenter, MacroExercises

makedocs(sitename="Exercises in writing macros for Julia")
deploydocs(
    repo = "github.com/jhidding/MacroExercises.jl.git"
)

