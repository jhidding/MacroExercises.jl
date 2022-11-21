# ~\~ language=Julia filename=src/Polynomials.jl
# ~\~ begin <<docs/src/polynomials.md|src/Polynomials.jl>>[init]
module Polynomials
# ~\~ begin <<docs/src/polynomials.md|polynomials>>[init]
struct Polynomial{T}
    c::Vector{T}
end

function Polynomial(c::T...) where T<:Number
    Polynomial(T[c...])
end

function compute_vectorized(f::Polynomial{T}, x::T) where T<:Number
    sum(f.c .* x.^(0:(length(f.c)-1)))
end

function compute_tight_loop(f::Polynomial{T}, x::T) where T<:Number
    result = 0
    xpow = 1
    for c in f.c
        result += xpow * c
        xpow *= x
    end
end
# ~\~ end
end
# ~\~ end
