#!/bin/bash

function startJaeger {
	if [ ! -d jaeger-1.24.0-linux-amd64 ]
	then
		wget https://github.com/jaegertracing/jaeger/releases/download/v1.24.0/jaeger-1.24.0-linux-amd64.tar.gz
		tar -xvf jaeger-1.24.0-linux-amd64.tar.gz
		rm jaeger-1.24.0-linux-amd64.tar.gz
	fi
	cd jaeger-1.24.0-linux-amd64
	./jaeger-all-in-one &> jaeger.log &
	cd ..
}

function cleanup {
	[ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-$RECURSION_DEPTH-${k}.log
	echo >>${BASE_DIR}/OpenTelemetry.log
	echo >>${BASE_DIR}/OpenTelemetry.log
	sync
	sleep ${SLEEP_TIME}
}

function runNoInstrumentation {
    # No instrumentation
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}/OpenTelemetry.log
    ${JAVABIN}java ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth $RECURSION_DEPTH \
        ${MOREPARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
}

function runOpenTelemetryNoLogging {
    # OpenTelemetry Instrumentation Logging Deactivated
    k=`expr ${k} + 1`
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}/OpenTelemetry.log
    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_LOGGING_DEACTIVATED} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth $RECURSION_DEPTH \
        ${MOREPARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
}

function runOpenTelemetryLogging {
    # OpenTelemetry Instrumentation Logging
    k=`expr ${k} + 1`
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}/OpenTelemetry.log
    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_LOGGING} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth $RECURSION_DEPTH \
        ${MOREPARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
    if [ ! "$DEBUG" = true ]
    then
    	echo "DEBUG is $DEBUG, deleting opentelemetry logging file"
    	rm ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
    fi
}

function runOpenTelemetryZipkin {
    # OpenTelemetry Instrumentation Zipkin
    k=`expr ${k} + 1`
    startZipkin
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}/OpenTelemetry.log
    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_ZIPKIN} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth $RECURSION_DEPTH \
        ${MOREPARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
    stopBackgroundProcess
    sleep $SLEEP_TIME
}

function runOpenTelemetryJaeger {
	# OpenTelemetry Instrumentation Jaeger
	k=`expr ${k} + 1`
	startJaeger
	echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
	echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}/OpenTelemetry.log
	${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_JAEGER} ${JAR} \
		--output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
		--total-calls ${TOTAL_NUM_OF_CALLS} \
		--method-time ${METHOD_TIME} \
		--total-threads ${THREADS} \
		--recursion-depth $RECURSION_DEPTH \
		${MOREPARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
	stopBackgroundProcess
	sleep $SLEEP_TIME
}

function runOpenTelemetryPrometheus {
	# OpenTelemetry Instrumentation Prometheus
	k=`expr ${k} + 1`
	startPrometheus
	echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
	echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}/OpenTelemetry.log
	${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_PROMETHEUS} ${JAR} \
		--output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
		--total-calls ${TOTAL_NUM_OF_CALLS} \
		--method-time ${METHOD_TIME} \
		--total-threads ${THREADS} \
		--recursion-depth $RECURSION_DEPTH \
		${MOREPARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
	stopBackgroundProcess
	sleep $SLEEP_TIME
}

JAVABIN=""

BASE_DIR=$(pwd)
RSCRIPT_PATH="../stats.csv.r"

source ../common-functions.sh
source labels.sh

#MOREPARAMS="--quickstart"
MOREPARAMS="--application moobench.application.MonitoredClassSimple ${MOREPARAMS}"

TIME=`expr ${METHOD_TIME} \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_OF_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Cleaning and recreating '$RESULTS_DIR'"
(rm -rf ${RESULTS_DIR}/**csv) && mkdir -p ${RESULTS_DIR}
#mkdir ${RESULTS_DIR}stat/

# Clear OpenTelemetry.log and initialize logging
rm -f ${BASE_DIR}/OpenTelemetry.log
touch ${BASE_DIR}/OpenTelemetry.log

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} "
JAVAARGS="${JAVAARGS} -Xms1G -Xmx2G"
JAVAARGS="${JAVAARGS} -verbose:gc "
JAR="-jar MooBench.jar"

checkMoobenchApplication

getOpentelemetryAgent

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_OPENTELEMETRY_BASIC="${JAVAARGS} -javaagent:${BASE_DIR}/lib/opentelemetry-javaagent-all.jar -Dotel.resource.attributes=service.name=moobench -Dotel.instrumentation.methods.include=moobench.application.MonitoredClassSimple[monitoredMethod];moobench.application.MonitoredClassThreaded[monitoredMethod]"
JAVAARGS_OPENTELEMETRY_LOGGING_DEACTIVATED="${JAVAARGS_OPENTELEMETRY_BASIC} -Dotel.traces.exporter=logging -Dotel.traces.sampler=always_off"
JAVAARGS_OPENTELEMETRY_LOGGING="${JAVAARGS_OPENTELEMETRY_BASIC} -Dotel.traces.exporter=logging"
JAVAARGS_OPENTELEMETRY_ZIPKIN="${JAVAARGS_OPENTELEMETRY_BASIC} -Dotel.traces.exporter=zipkin -Dotel.metrics.exporter=none"
JAVAARGS_OPENTELEMETRY_JAEGER="${JAVAARGS_OPENTELEMETRY_BASIC} -Dotel.traces.exporter=none -Dotel.traces.exporter=jaeger"
JAVAARGS_OPENTELEMETRY_PROMETHEUS="${JAVAARGS_OPENTELEMETRY_BASIC} -Dotel.traces.exporter=none -Dotel.metrics.exporter=prometheus"

writeConfiguration

## Execute Benchmark
for ((i=1;i<=${NUM_OF_LOOPS};i+=1)); do
    k=0
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}"
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}" >>${BASE_DIR}/OpenTelemetry.log

    runNoInstrumentation
    cleanup

    runOpenTelemetryNoLogging
    cleanup

    runOpenTelemetryLogging
    cleanup
    
    runOpenTelemetryZipkin
    cleanup
    
    runOpenTelemetryPrometheus
    cleanup

    printIntermediaryResults
done

# Create R labels
LABELS=$(createRLabels)
run-r

cleanup-results

#zip -jqr ${RESULTS_DIR}stat.zip ${RESULTS_DIR}stat
#rm -rf ${RESULTS_DIR}stat/
mv ${BASE_DIR}/OpenTelemetry.log ${RESULTS_DIR}/OpenTelemetry.log
[ -f ${RESULTS_DIR}hotspot-1-${RECURSION_DEPTH}-1.log ] && grep "<task " ${RESULTS_DIR}hotspot-*.log >${RESULTS_DIR}log.log
[ -f ${BASE_DIR}errorlog.txt ] && mv ${BASE_DIR}errorlog.txt ${RESULTS_DIR}

