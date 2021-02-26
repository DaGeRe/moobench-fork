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
export VERSION_PATH=`curl "https://oss.sonatype.org/service/local/repositories/snapshots/content/net/kieker-monitoring/kieker/" | grep '<resourceURI>' | sed 's/ *<resourceURI>//g' | sed 's/<\/resourceURI>//g' | grep '/$'`
export AGENT_PATH=`curl "${VERSION_PATH}" | grep 'aspectj.jar</resourceURI' | sort | sed 's/ *<resourceURI>//g' | sed 's/<\/resourceURI>//g' | tail -1`
curl "${AGENT_PATH}" > "${AGENT}"
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
