// ~\~ language=C++ filename=src/polynomials.cpp
// ~\~ begin <<docs/src/polynomials.md|src/polynomials.cpp>>[init]
#include <vector>
#include <iostream>
#include <chrono>

double compute_tight_loop(std::vector<double> &cs, double x) {
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

    std::vector<double> c{1.0, -3.0, 2.0, -4.0, 1.5, 0.3, -0.1};
    std::cout << compute_tight_loop(c, 10.0) << std::endl;
    auto start = std::chrono::high_resolution_clock::now();
    double grant_total = 0.0;
    for (unsigned i = 0; i < 1000; ++i) {
        double total = 0.0;
        for (unsigned j = 0; j < 100000; ++j) {
            double x = j / 100000.0;
            total += compute_tight_loop(c, x);
        }
        grant_total += total / 100000;
    }
    auto stop = std::chrono::high_resolution_clock::now();
    std::cout << "total: " << grant_total << std::endl
              << "duration: " << duration_cast<milliseconds>(stop - start) << std::endl;
    return 0;
}
// ~\~ end
