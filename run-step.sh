#!/bin/bash

./frameworks/Kieker-python/benchmark.sh || exit
./frameworks/Kieker-java/benchmark.sh || exit
./frameworks/OpenTelemetry-java/benchmark.sh || exit
./frameworks/inspectIT-java/benchmark.sh || exit

echo "copy"
cp -v frameworks/Kieker-python/results-Kieker-python/results.yaml kieker-python-results.yaml
cp -v frameworks/Kieker-java/results-Kieker-java/results.yaml kieker-java-results.yaml
cp -v frameworks/OpenTelemetry-java/results-OpenTelemetry-java/results.yaml open-telementry-results.yaml
cp -v frameworks/inspectIT-java/results-inspectIT-java/results.yaml inspect-it-results.yaml

# end

