# Polynomials
If you're not sold on macros for their expressiveness, here's something new for you. One reason why macros can be so powerful, is that they let us write little code generators for things that we normally wouldn't bother with. This means getting potentially huge performance gains. We'll work through an example where we need to compute some polynomial.

``` {.julia file=src/Polynomials.jl}
module Polynomials
<<polynomials>>
end
```

A polynomial is a function defined by some finite power series,

```math
f(x) = \sum_{i = 0}^{n} c_i x^i,
```

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
```

The notation in `compute_vectorized` is very compact, and it closely mimics the actual function definition that we gave for a polynomial. Is it also fast?

```julia
using MacroExercises.Polynomials: Polynomial, compute_vectorized, compute_tight_loop

f = Polynomial(1.0, -3.0, 2.0, -4.0, 1.5, 0.3, -0.1)
xs = LinRange(0.0, 1.0, 100000)

test_f1(n) = for _ in 1:n
    xs .|> x -> compute_vectorized(f, x)
end

# compile
test_f1(1)

# time
@elapsed test_f1(100)
```

On my machine this takes about two seconds. A profiler reveals that most time (about 70%) is spent computing the `:^` function. We can be more efficient if we use incremental multiplication.

``` {.julia #polynomials}
function compute_tight_loop(f::Polynomial{T}, x::T) where T<:Number
    result = 0
    xpow = 1
    for c in f.c
        result += xpow * c
        xpow *= x
    end
    result
end
```

```julia
test_f2(n) = for _ in 1:n
    xs .|> x -> compute_tight_loop(f, x)
end

test_f2(1)

@elapsed test_f2(1000)
```

This takes about three seconds on my machine, so the tight loop version is an order of magnitude faster (note the sample size). Can we do better? Now it starts to get interesting! We'll generate code as if we unroll the for-loop for a specific case of a polynomial manualy.

``` {.julia #polynomials}
function expand(f::Polynomial{T}) where T<:Number
    :(function (x::$T)
        r = $(f.c[1])
        xp = x
        $((:(r += xp*$c; xp*=x) for c in f.c[2:end-1])...)
        r + xp * $(f.c[end])
    end)
end
```

What does that generated code look like?

```@example 1
using MacroExercises.Polynomials: Polynomial, expand

Base.remove_linenums!(
    expand(Polynomial(1.0, 0.5, 0.333, 0.25)))
```

Now, test it for speed:

```julia
f_unroll = eval(expand(f))
test_f3(n) = sum(sum(f_unroll.(xs)) for _ in 1:n)
test_f3(1)
@elapsed test_f3(1000)
```

For me this computes in 0.12 seconds. That is 25 times faster than the dynamic `tight_loop` version. I think that is really amazing. For reference, here is the C++ equivalent of the tight loop version. I had to try really hard to make it not optimize away results that weren't used afterwards.

``` {.cpp file=src/polynomials.cpp}
#include <vector>
#include <iostream>
#include <chrono>
#include <algorithm>
#include <numeric>

double compute_tight_loop(std::vector<double> const &cs, double x) {
    double r = 0.0;
    double xp = 1.0;
    for (auto c : cs) {
        r += xp * c;
        xp *= x;
    }
    return r;
}

int main() {
    using std::chrono::duration_cast;
    using std::chrono::milliseconds;
    using std::accumulate;

    std::vector<double> c{1.0, -3.0, 2.0, -4.0, 1.5, 0.3, -0.1};
    std::cout << compute_tight_loop(c, 10.0) << std::endl;
    std::vector<double> input(100000), output(100000);
    for (unsigned i = 0; i < 100000; ++i) { input[i] = i / 100000.0; }
    auto start = std::chrono::high_resolution_clock::now();
    double grant_total = 0.0;
    for (unsigned i = 0; i < 1000; ++i) {
        for (unsigned j = 0; j < 100000; ++j) { output[j] = compute_tight_loop(c, input[j]); }
        grant_total += accumulate(output.begin(), output.end(), 0.0);
    }
    auto stop = std::chrono::high_resolution_clock::now();
    std::cout << "total: " << grant_total << std::endl
              << "duration: " << duration_cast<milliseconds>(stop - start) << std::endl;
    return 0;
}
```

This gives me about 300ms on my laptop, against 120ms for the Julia version. So how could Julia be faster than C++? We were able to compile our polynomial code for a specific polynomial on the fly, creating a function that does not need to access memory. The equivalent in C++ would be to generate code and pass that through GCC and then run it: that is insane.

## Horner's method
There is a more efficient way to evaluate a polynomial, called Horner's method (thanks Nicos Pitsianis for pointing it out to me). Let's implement it and compare. The method works by starting at the highest order coefficient.

``` {.julia #polynomials}
function horner(f::Polynomial{T}) where T<:Number
    r = :($(f.c[end]))
    for c in reverse(f.c[1:end-1])
        r = :($r * x + $c)
    end
    :(function (x::$T)
        $r
    end)
end
```

This function also uses a recursion to grow the expression, creating somewhat pretier code.

```@example 1
using MacroExercises.Polynomials: horner

Base.remove_linenums!(
    horner(Polynomial(1.0, 0.5, 0.333, 0.25)))
```

So, how do they compare?

```@repl
using MacroExercises.Polynomials: Polynomial, expand, horner
using BenchmarkTools
f = Polynomial((1.0 ./ factorial.(0:11))...)
xs = collect(LinRange(0.0, 1.0, 1000))  # make sure to collect
f_unroll = eval(expand(f))
f_unroll(1.0)  # should be close to e
f_horner = eval(horner(f))
f_horner(1.0)
@benchmark xs .|> f_unroll
@benchmark xs .|> f_horner
```

I don't know what this benchmark will do on the Github servers, but on my laptop this gives 1.466μs and 1.346μs minimum runtime. So Horner's method gives me close to 10% speed-up. Let's compare this with the C++ code, using a better benchmarking tool (`google-benchmark` in this case)!

The difference is a bit less than my previous amateurish attempt at a benchmark, but a real difference is still there: 1.692μs for Horner's method.

``` {.cpp file=src/horner.cpp}
#include <benchmark/benchmark.h>
#include <vector>

constexpr unsigned ORDER = 11;
constexpr unsigned N = 1000;

double polynome(std::vector<double> const &cs, double x) {
    double r = cs.front();
    double xp = x;
    for (unsigned i = 1; i < cs.size() - 1; ++i) {
        r += xp * cs[i];
        xp *= x;
    }
    r += xp * cs.back();
    return r;
}

double horner(std::vector<double> const &cs, double x) {
    double r = cs.back();
    for (unsigned i = 1; i < cs.size(); ++i)
        r = r * x + cs[cs.size() - 1 - i];
    return r;
}

struct BMSetup {
    std::vector<double> xs, ys;
    std::vector<double> cs;

    BMSetup(): xs(N), ys(N), cs(ORDER+1) {
        for (unsigned i = 0; i < N; ++i)
            xs[i] = i / double(N);
        unsigned j = 1;
        cs[0] = 1.0;
        for (unsigned i = 1; i < ORDER+1; ++i, j *= i)
            cs[i] = 1.0 / double(j);
    }
};

static void bm_horner(benchmark::State &state) {
    BMSetup setup{};
    for (auto _ : state) {
        for (unsigned i = 0; i < N; ++i) {
            setup.ys[i] = horner(setup.cs, setup.xs[i]);
        }
    }
}

BENCHMARK(bm_horner);

static void bm_polynome(benchmark::State &state) {
    BMSetup setup{};
    for (auto _ : state) {
        for (unsigned i = 0; i < N; ++i) {
            setup.ys[i] = polynome(setup.cs, setup.xs[i]);
        }
    }
}

BENCHMARK(bm_polynome);

BENCHMARK_MAIN();
```
