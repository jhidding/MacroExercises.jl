.PHONY: docs

docs:
	cd docs; \
	julia --project=.. make.jl

all: docs

