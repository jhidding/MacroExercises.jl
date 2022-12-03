// ~\~ language=C++ filename=src/horner.cpp
// ~\~ begin <<docs/src/polynomials.md|src/horner.cpp>>[init]
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
// ~\~ end
