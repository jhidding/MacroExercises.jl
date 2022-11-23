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
# ~\~ end
# ~\~ begin <<docs/src/polynomials.md|polynomials>>[1]
function compute_tight_loop(f::Polynomial{T}, x::T) where T<:Number
    result = 0
    xpow = 1
    for c in f.c
        result += xpow * c
        xpow *= x
    end
    result
end
# ~\~ end
# ~\~ begin <<docs/src/polynomials.md|polynomials>>[2]
function expand(f::Polynomial{T}) where T<:Number
    :(function (x::$T)
        r = $(f.c[1])
        xp = x
        $((:(r += xp*$c; xp*=x) for c in f.c[2:end-1])...)
        r + xp * $(f.c[end])
    end)
end
# ~\~ end
end
# ~\~ end
