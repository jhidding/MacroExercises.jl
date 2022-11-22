.PHONY: docs

docs:
	cd docs; \
	julia --project=.. --compile=min -O0 make.jl

all: docs

