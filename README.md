# MacroExercises.jl
Adventures in macro land. I'll do some experiments with metaprogramming in Julia. Specifically, I'm curious to see what kind of performance we can get when using code generation and macros.

See [https://jhidding.github.io/MacroExercises.jl](https://jhidding.github.io/MacroExercises.jl).

Ideas I have:

- [x] Compute some polynomial that was given at runtime. (Julia beats reasonable C++ by a factor of three)
- [ ] Encode/Decode structs to/from JSON, including schema validation
- [ ] Geometric algebra: derive multiplication rules on the fly

## Format
This work is completely contained in its documentation through the use of Entangled. The rendering by `Documenter.jl` does'nt do anything with the labels I'm giving to code blocks, so the reading experience leaves something to be improved. Maybe I'll introduce a Pandoc pass before rendering...
