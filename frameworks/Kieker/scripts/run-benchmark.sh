#!/bin/bash

BASE_DIR=$(cd "$(dirname "$0")"; pwd)

# load configuration and common functions
if [ -f "${BASE_DIR}/config" ] ; then
	. ${BASE_DIR}/config
else
	echo "Missing configuration: ${BASE_DIR}/config"
	exit 1
fi
if [ -f "${BASE_DIR}/common-functions" ] ; then
	. ${BASE_DIR}/common-functions
else
	echo "Missing configuration: ${BASE_DIR}/common-functions"
	exit 1
fi

## setup

export RESULT_FILE="${BASE_DIR}/results-kieker/results-text.csv"
COLLECTED_DATA_FILE="${BASE_DIR}/results.csv"
BENCHMARK="${BASE_DIR}/benchmark.sh"

##
cd ${BASE_DIR}

## setup
# install benchmark
tar -xvpf ${BASE_DIR}/../../../benchmark/build/distributions/benchmark.tar
# get agent
curl "https://oss.sonatype.org/service/local/repositories/snapshots/content/net/kieker-monitoring/kieker/1.15-SNAPSHOT/kieker-1.15-20201102.131525-117-aspectj.jar" > "${AGENT}"
# copy receiver
tar -xvpf ${BASE_DIR}/../../../tools/receiver/build/distributions/receiver.tar
# copy result compiler
tar -xvpf ${BASE_DIR}/../../../tools/compile-results/build/distributions/compile-results.tar

# Create benchmark results
mkdir -p ${BASE_DIR}/results-kieker

rm -f ${COLLECTED_DATA_FILE}

## running the benchmark
${BENCHMARK} # > /dev/null 2>&1

# end
