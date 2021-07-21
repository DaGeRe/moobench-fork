#!/bin/bash

for depth in 2 4 8 16 32 64 128
do
	export RECURSION_DEPTH=$depth
	echo "Running $depth"
	./benchmark.sh &> results-opentelemetry/$depth.txt
	mv results-opentelemetry/results.zip results-opentelemetry/results-$RECURSION_DEPTH.zip
done
