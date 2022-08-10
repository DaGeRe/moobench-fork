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
# check command line parameters
#
if [ "$1" == "" ] ; then
	MODE="execute"
else
	if [ "$1" == "execute" ] ; then
		MODE="execute"
	else
		mode="test"
	fi
	OPTION="$2"
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

# Find receiver and extract it
checkFile receiver "${RECEIVER_ARCHIVE}"
tar -xpf "${RECEIVER_ARCHIVE}"
RECEIVER_BIN="${BASE_DIR}/receiver/bin/receiver"

PARENT=`dirname "${RESULTS_DIR}"`

checkDirectory DATA_DIR "${DATA_DIR}" create
checkDirectory result-base "${PARENT}"
checkFile ApsectJ-Agent "${AGENT}"
checkExecutable Receiver "${RECEIVER_BIN}"
checkFile Labels "${BASE_DIR}/labels.sh"
checkFile R-script "${RSCRIPT_PATH}"
checkDirectory results-directory "${RESULTS_DIR}" recreate
checkFile log "${DATA_DIR}/kieker.log" clean
checkExecutable java "${JAVA_BIN}"
checkExecutable moobench "${MOOBENCH_BIN}"
checkExecutable receiver "${RECEIVER_BIN}"
checkFile aop-file "${AOP}"

TIME=`expr ${METHOD_TIME} \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_OF_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} `
info "Experiment will take circa ${TIME} seconds."

# general server arguments
JAVA_ARGS="-Xms1G -Xmx2G"

LTW_ARGS="-javaagent:${AGENT} --illegal-access=permit -Dorg.aspectj.weaver.showWeaveInfo=true -Daj.weaving.verbose=true -Dkieker.monitoring.skipDefaultAOPConfiguration=true -Dorg.aspectj.weaver.loadtime.configuration=file://${AOP}"

KIEKER_ARGS="-Dlog4j.configuration=log4j.cfg -Dkieker.monitoring.name=KIEKER-BENCHMARK -Dkieker.monitoring.adaptiveMonitoring.enabled=false -Dkieker.monitoring.periodicSensorsExecutorPoolSize=0"

# JAVA_ARGS used to configure and setup a specific writer
declare -a WRITER_CONFIG
# Receiver setup if necessary
declare -a RECEIVER
# Title
declare -a TITLE

#
# Different writer setups
#
WRITER_CONFIG[0]=""
WRITER_CONFIG[1]="-Dkieker.monitoring.enabled=false -Dkieker.monitoring.writer=kieker.monitoring.writer.dump.DumpWriter"
WRITER_CONFIG[2]="-Dkieker.monitoring.enabled=true -Dkieker.monitoring.writer=kieker.monitoring.writer.dump.DumpWriter"
WRITER_CONFIG[3]="-Dkieker.monitoring.enabled=true -Dkieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter -Dkieker.monitoring.writer.filesystem.FileWriter.logStreamHandler=kieker.monitoring.writer.filesystem.TextLogStreamHandler -Dkieker.monitoring.writer.filesystem.FileWriter.customStoragePath=${DATA_DIR}/"
WRITER_CONFIG[4]="-Dkieker.monitoring.enabled=true -Dkieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter -Dkieker.monitoring.writer.filesystem.FileWriter.logStreamHandler=kieker.monitoring.writer.filesystem.BinaryLogStreamHandler -Dkieker.monitoring.writer.filesystem.FileWriter.bufferSize=8192 -Dkieker.monitoring.writer.filesystem.FileWriter.customStoragePath=${DATA_DIR}/"
WRITER_CONFIG[5]="-Dkieker.monitoring.writer=kieker.monitoring.writer.tcp.SingleSocketTcpWriter -Dkieker.monitoring.writer.tcp.SingleSocketTcpWriter.port=2345"
RECEIVER[5]="${RECEIVER_BIN} 2345"

#
# Write configuration
#

uname -a > "${RESULTS_DIR}/configuration.txt"
"${JAVA_BIN}" "${JAVA_ARGS}" -version 2>> "${RESULTS_DIR}/configuration.txt"
cat << EOF >> "${RESULTS_DIR}/configuration.txt"
JAVA_ARGS: ${JAVA_ARGS}

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

if [ "$MODE" == "execute" ] ; then
   if [ "$OPTION" == "" ] ; then
     executeBenchmark
   else
     executeBenchmarkBody $OPTION 1 1
   fi

   # Create R labels
   LABELS=$(createRLabels)
   runStatistics
   cleanupResults
else
   executeBenchmarkBody $OPTION 1 1
fi

info "Done."

# end
