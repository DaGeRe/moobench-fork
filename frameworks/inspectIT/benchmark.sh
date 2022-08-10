#!/bin/bash

#
# inspectIT benchmark script
#
# Usage: benchmark.sh

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

if [ -f "${BASE_DIR}/../common-functions.sh" ] ; then
	source "${BASE_DIR}/../common-functions.sh"
else
	echo "Missing library: ${BASE_DIR}/../common-functions.sh"
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

# load agent
getAgent

checkExecutable MooBench "${MOOBENCH_BIN}"
checkFile log "${BASE_DIR}/inspectIT.log" clean
checkDirectory results-directory "${RESULTS_DIR}" recreate
checkExecutable java "${JAVA_BIN}"
checkFile R-script "${RSCRIPT_PATH}"


TIME=`expr ${METHOD_TIME} \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_OF_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} `
info "Experiment will take circa ${TIME} seconds."

JAVA_ARGS="-server"
JAVA_ARGS="${JAVA_ARGS} -Xms1G -Xmx2G"
JAVA_ARGS="${JAVA_ARGS} -verbose:gc "

JAVA_ARGS_NOINSTR="${JAVA_ARGS}"
JAVA_ARGS_LTW="${JAVA_ARGS} -javaagent:${BASE_DIR}/agent/inspectit-ocelot-agent-1.11.1.jar -Djava.util.logging.config.file=${BASE_DIR}/config/logging.properties"
JAVA_ARGS_INSPECTIT_DEACTIVATED="${JAVA_ARGS_LTW} -Dinspectit.service-name=moobench-inspectit -Dinspectit.exporters.metrics.prometheus.enabled=false -Dinspectit.exporters.tracing.zipkin.enabled=false -Dinspectit.config.file-based.path=${BASE_DIR}/config/onlyInstrument/"
JAVA_ARGS_INSPECTIT_NULLWRITER="${JAVA_ARGS_LTW} -Dinspectit.service-name=moobench-inspectit -Dinspectit.exporters.metrics.prometheus.enabled=false -Dinspectit.exporters.tracing.zipkin.enabled=false -Dinspectit.config.file-based.path=${BASE_DIR}/config/nullWriter/"
JAVA_ARGS_INSPECTIT_ZIPKIN="${JAVA_ARGS_LTW} -Dinspectit.service-name=moobench-inspectit -Dinspectit.exporters.metrics.prometheus.enabled=false -Dinspectit.exporters.tracing.zipkin.url=http://127.0.0.1:9411/api/v2/spans -Dinspectit.config.file-based.path=${BASE_DIR}/config/zipkin/"
JAVA_ARGS_INSPECTIT_PROMETHEUS="${JAVA_ARGS_LTW} -Dinspectit.service-name=moobench-inspectit -Dinspectit.exporters.metrics.zipkin.enabled=false -Dinspectit.exporters.metrics.prometheus.enabled=true -Dinspectit.config.file-based.path=${BASE_DIR}/config/prometheus/"

info "RESULTS_DIR: ${RESULTS_DIR}"
info "RAWFN: $RAWFN"
writeConfiguration

#
# Run benchmark
#

info "----------------------------------"
info "Running benchmark..."
info "----------------------------------"

## Execute Benchmark
for ((i=1;i<=${NUM_OF_LOOPS};i+=1)); do
    k=0
    info "## Starting iteration ${i}/${NUM_OF_LOOPS}"
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}" >> "${BASE_DIR}/inspectIT.log"

    runNoInstrumentation
    cleanup

    runInspectITDeactivated
    cleanup
    
    runInspectITNullWriter
    cleanup

    runInspectITZipkin
    cleanup
    
    runInspectITPrometheus
    cleanup
    
    printIntermediaryResults
done

mv "${BASE_DIR}/inspectIT.log" "${RESULTS_DIR}/inspectIT.log"
[ -f "${RESULTS_DIR}/Hotspot-1-${RECURSION_DEPTH}-1.log" ] && grep "<task " ${RESULTS_DIR}/hotspot-*.log > "${RESULTS_DIR}/log.log"
[ -f "${BASE_DIR}/errorlog.txt" ] && mv "${BASE_DIR}/errorlog.txt" "${RESULTS_DIR}"

# Create R labels
LABELS=$(createRLabels)
runStatistics

## Clean up raw results
zip -jqr "${RESULTS_DIR}/results.zip" ${RAWFN}*
rm ${RAWFN}*

info "Done."

# end
