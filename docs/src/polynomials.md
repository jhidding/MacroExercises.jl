# Polynomials

``` {.julia file=src/Polynomials.jl}
module Polynomials
<<polynomials>>
end
```

Suppose we need to do some work with polynomials. A polynomial is a function defined by some finite power series,

$$f(x) = \sum_{i = 0}^{n < \infinity} c_i x^i,$$

where we refer to $c_i$ as the coefficients of the polynomial. We may store a polynomial as a Vector.

``` {.julia #polynomials}
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
```

```@example 1
using MacroExercises.Polynomials: Polynomial, compute_vectorized, compute_tight_loop

f = Polynomial(1.0, -3.0, 2.0, -4.0, 1.5, 0.3, -0.1)

@time compute_vectorized.(f, LinRange(0.0, 1.0, 1000))
@time compute_tight_loop.(f, LinRange(0.0, 1.0, 1000))
```
```

