#!/bin/bash
echo "This scripts benchmarks all defined monitoring frameworks, currently InspectIT, Kieker and OpenTelemetry"

start=$(pwd)
for benchmark in inspectIT OpenTelemetry
do
        cd $benchmark
        ./benchmark.sh &> $start/log_$benchmark.txt
        cd $start
done

cd Kieker/scripts
./benchmark.sh &> $start/log_Kieker.txt
cd $start
