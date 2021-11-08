#!/bin/bash
echo "This scripts benchmarks all defined monitoring frameworks, currently InspectIT, Kieker and OpenTelemetry"

start=$(pwd)
for benchmark in inspectIT OpenTelemetry Kieker
do
        cd $benchmark
        ./benchmark.sh &> $start/log_$benchmark.txt
        cd $start
done

