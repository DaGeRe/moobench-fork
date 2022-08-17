#!/bin/bash

#
# Kieker benchmark script
#
# Usage: benchmark.sh [execute|test]

# configure base dir
BASE_DIR=$(cd "$(dirname "$0")"; pwd)

#
# source functionality
#

if [ ! -d "${BASE_DIR}" ] ; then
	echo "Base directory ${BASE_DIR} does not exist."
	exit 1
fi

# load configuration and common functions
if [ -f "${BASE_DIR}/config.rc" ] ; then
	source "${BASE_DIR}/config.rc"
else
	echo "Missing configuration: ${BASE_DIR}/config.rc"
	exit 1
fi

if [ -f "${MAIN_DIR}/frameworks/common-functions.sh" ] ; then
	source "${MAIN_DIR}/frameworks/common-functions.sh"
else
	echo "Missing library: ${MAIN_DIR}/frameworks/common-functions.sh"
	exit 1
fi

if [ -f "${BASE_DIR}/functions.sh" ] ; then
	source "${BASE_DIR}/functions.sh"
else
	echo "Missing: ${BASE_DIR}/functions.sh"
	exit 1
fi
if [ -f "${BASE_DIR}/labels.sh" ] ; then
	source "${BASE_DIR}/labels.sh"
else
	echo "Missing file: ${BASE_DIR}/labels.sh"
	exit 1
fi
#
# Setup
#

info "----------------------------------"
info "Setup..."
info "----------------------------------"

cd "${BASE_DIR}"

# load agent
getAgent

checkDirectory data-dir "${DATA_DIR}" create
checkDirectory results-directory "${RESULTS_DIR}" recreate
PARENT=`dirname "${RESULTS_DIR}"`
checkDirectory result-base "${PARENT}"

# Find receiver and extract it
checkFile receiver "${RECEIVER_ARCHIVE}"
tar -xpf "${RECEIVER_ARCHIVE}"
RECEIVER_BIN="${BASE_DIR}/receiver/bin/receiver"
checkExecutable receiver "${RECEIVER_BIN}"

checkFile R-script "${RSCRIPT_PATH}"
checkFile log "${DATA_DIR}/kieker.log" clean

showParameter

TIME=`expr ${METHOD_TIME} \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_OF_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} `
info "Experiment will take circa ${TIME} seconds."

# JAVA_ARGS used to configure and setup a specific writer
declare -a WRITER_CONFIG
# Receiver setup if necessary
declare -a RECEIVER
# Title
declare -a TITLE

RECEIVER[5]="${RECEIVER_BIN} 2345"

#
# Write configuration
#

uname -a > "${RESULTS_DIR}/configuration.txt"
cat << EOF >> "${RESULTS_DIR}/configuration.txt"
Runtime: circa ${TIME} seconds

SLEEP_TIME=${SLEEP_TIME}
NUM_OF_LOOPS=${NUM_OF_LOOPS}
TOTAL_NUM_OF_CALLS=${TOTAL_NUM_OF_CALLS}
METHOD_TIME=${METHOD_TIME}
RECURSION_DEPTH=${RECURSION_DEPTH}
EOF

info "Ok"

sync


#
# Run benchmark
#

info "----------------------------------"
info "Running benchmark..."
info "----------------------------------"

benchmark

# cleanup

info "Done."

# end
