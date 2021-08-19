#!/bin/bash

function runNoInstrumentation {
    # No instrumentation
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}inspectit.log
    ${JAVABIN}java ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${RECURSION_DEPTH} \
        ${MOREPARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
}

function runInspectITDeactivated {
    # InspectIT (minimal)
    k=`expr ${k} + 1`
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}inspectit.log
    sleep $SLEEP_TIME
    ${JAVABIN}java ${JAVAARGS_INSPECTIT_DEACTIVATED} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${RECURSION_DEPTH} \
        --force-terminate \
        ${MOREPARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
    sleep $SLEEP_TIME
}


function runInspectITZipkin {
    # InspectIT (minimal)
    k=`expr ${k} + 1`
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}inspectit.log
    startZipkin
    sleep $SLEEP_TIME
    ${JAVABIN}java ${JAVAARGS_INSPECTIT_ZIPKIN} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${RECURSION_DEPTH} \
        --force-terminate \
        ${MOREPARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
    sleep $SLEEP_TIME
    stopBackgroundProcess
}

function runInspectITPrometheus {
    # InspectIT (minimal)
    k=`expr ${k} + 1`
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}inspectit.log
    startPrometheus
    sleep $SLEEP_TIME
    ${JAVABIN}java ${JAVAARGS_INSPECTIT_PROMETHEUS} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${RECURSION_DEPTH} \
        --force-terminate \
        ${MOREPARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
    sleep $SLEEP_TIME
    stopBackgroundProcess
}

function cleanup {
	[ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
	echo >>${BASE_DIR}inspectit.log
	echo >>${BASE_DIR}inspectit.log
	sync
	sleep ${SLEEP_TIME}
}

function getSum {
  awk '{sum += $1; square += $1^2} END {print "Average: "sum/NR" Standard Deviation: "sqrt(square / NR - (sum/NR)^2)" Count: "NR}'
}

JAVABIN=""

BASE_DIR=$(pwd)
RSCRIPT_PATH="../stats.csv.r"

source ../common-functions.sh
source labels.sh

checkMoobenchApplication

getInspectItAgent

#MOREPARAMS="--quickstart"
MOREPARAMS="${MOREPARAMS}"

TIME=`expr ${METHODTIME} \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} + ${SLEEPTIME} \* 4 \* ${NUM_OF_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '$RESULTS_DIR'"
(rm -rf ${RESULTS_DIR}) && mkdir -p ${RESULTS_DIR}

# Clear inspectit.log and initialize logging
rm -f ${BASE_DIR}inspectit.log
touch ${BASE_DIR}inspectit.log

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -Xms1G -Xmx2G"
JAVAARGS="${JAVAARGS} -verbose:gc "
JAR="-jar MooBench.jar --application moobench.application.MonitoredClassSimple"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASE_DIR}/agent/inspectit-ocelot-agent-1.11.1.jar -Djava.util.logging.config.file=${BASE_DIR}config/logging.properties"
JAVAARGS_INSPECTIT_DEACTIVATED="${JAVAARGS_LTW} -Dinspectit.service-name=moobench-inspectit -Dinspectit.exporters.metrics.prometheus.enabled=false -Dinspectit.exporters.tracing.zipkin.enabled=false -Dinspectit.config.file-based.path=${BASE_DIR}config/onlyInstrument/"
JAVAARGS_INSPECTIT_ZIPKIN="${JAVAARGS_LTW} -Dinspectit.service-name=moobench-inspectit -Dinspectit.exporters.metrics.prometheus.enabled=false -Dinspectit.exporters.tracing.zipkin.url=http://127.0.0.1:9411/api/v2/spans -Dinspectit.config.file-based.path=${BASE_DIR}config/zipkin/"
JAVAARGS_INSPECTIT_PROMETHEUS="${JAVAARGS_LTW} -Dinspectit.service-name=moobench-inspectit -Dinspectit.exporters.metrics.zipkin.enabled=false -Dinspectit.exporters.metrics.prometheus.enabled=true -Dinspectit.config.file-based.path=${BASE_DIR}config/prometheus/"

echo "RESULTS_DIR: $RESULTS_DIR"
echo "RAWFN: $RAWFN"
writeConfiguration

## Execute Benchmark
for ((i=1;i<=${NUM_OF_LOOPS};i+=1)); do
    k=0
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}"
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}" >>${BASE_DIR}inspectit.log

    runNoInstrumentation
    cleanup

    runInspectITDeactivated
    cleanup

    runInspectITZipkin
    cleanup
    
    runInspectITPrometheus
    cleanup
    
    printIntermediaryResults
done
mv ${BASE_DIR}/inspectit.log ${RESULTS_DIR}/inspectit.log
[ -f ${RESULTS_DIR}Hotspot-1-${RECURSION_DEPTH}-1.log ] && grep "<task " ${RESULTS_DIR}hotspot-*.log >${RESULTS_DIR}log.log
[ -f ${BASE_DIR}errorlog.txt ] && mv ${BASE_DIR}errorlog.txt ${RESULTS_DIR}

# Create R labels
LABELS=$(createRLabels)
run-r

## Clean up raw results
zip -jqr ${RESULTS_DIR}/results.zip ${RAWFN}*
rm -f ${RAWFN}*
[ -f ${BASE_DIR}nohup.out ] && cp ${BASE_DIR}nohup.out ${RESULTS_DIR}
[ -f ${BASE_DIR}nohup.out ] && > ${BASE_DIR}nohup.out
