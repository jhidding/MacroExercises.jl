push!(LOAD_PATH,"../src/")

using Documenter, MacroExercises
# using Base.Filesystem: mktempdir, joinpath, mkdir, dirname

function noweb_label_pass(src, target_path)
    mkpath(joinpath(target_path, dirname(src)))
    run(pipeline(src, `awk -f noweb_label_pass.awk`, joinpath(target_path, src)))
end

function is_markdown(path)
    splitext(path)[2] == ".md"
end

sources = filter(is_markdown, readdir("./src", join=true))
path = mktempdir()
noweb_label_pass.(sources, path)

makedocs(source = joinpath(path, "src"), sitename="Exercises in writing macros for Julia")
deploydocs(
    repo = "github.com/jhidding/MacroExercises.jl.git"
)
