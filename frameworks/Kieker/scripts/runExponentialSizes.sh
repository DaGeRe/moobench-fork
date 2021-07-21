#!/bin/bash

RESULTS_DIR=results-kieker/
mkdir -p $RESULTS_DIR

for depth in 2 4 8 16 32 64 128
do
	export RECURSION_DEPTH=$depth
	echo "Running $depth"
	./benchmark.sh &> results-opentelemetry/$depth.txt
	mv $RESULTS_DIR/results.zip $RESULTS_DIR/results-$RECURSION_DEPTH.zip
done
