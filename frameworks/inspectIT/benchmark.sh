#!/bin/bash

function runNoInstrumentation {
    # No instrumentation
    echo " # ${i}.$RECURSION_DEPTH.${k} No instrumentation"
    echo " # ${i}.$RECURSION_DEPTH.${k} No instrumentation" >>${BASEDIR}inspectit.log
    ${JAVABIN}java ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${RECURSION_DEPTH} \
        ${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_"$RECURSION_DEPTH"_noinstrumentation.txt
}

function runInspectITZipkin {
    # InspectIT (minimal)
    k=`expr ${k} + 1`
    echo " # ${i}.$RECURSION_DEPTH.${k} InspectIT (minimal)"
    echo " # ${i}.$RECURSION_DEPTH.${k} InspectIT (minimal)" >>${BASEDIR}inspectit.log
    startZipkin
    sleep $SLEEP_TIME
    echo $JAVAARGS_INSPECTIT_MINIMAL
    echo $JAR
    ${JAVABIN}java ${JAVAARGS_INSPECTIT_MINIMAL} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${RECURSION_DEPTH} \
        --force-terminate \
        ${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_"$RECURSION_DEPTH"_inspectit.txt
    sleep $SLEEP_TIME
    stopBackgroundProcess
}

function cleanup {
	[ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
	echo >>${BASEDIR}inspectit.log
	echo >>${BASEDIR}inspectit.log
	sync
	sleep ${SLEEP_TIME}
}

function getSum {
  awk '{sum += $1; square += $1^2} END {print "Average: "sum/NR" Standard Deviation: "sqrt(square / NR - (sum/NR)^2)" Count: "NR}'
}

function printIntermediaryResults {
    echo -n "Intermediary results uninstrumented "
    cat results-inspectit/raw-*-"$RECURSION_DEPTH"-0.csv | awk -F';' '{print $2}' | getSum
    
    echo -n "Intermediary results inspectIT "
    cat results-inspectit/raw-*-"$RECURSION_DEPTH"-1.csv | awk -F';' '{print $2}' | getSum
}

JAVABIN=""

RSCRIPTDIR=r/
BASEDIR=./
RESULTSDIR="${BASEDIR}results-inspectit/"

source ../common-functions.sh

checkMoobenchApplication

getInspectItAgent

#MOREPARAMS="--quickstart"
MOREPARAMS="${MOREPARAMS}"

TIME=`expr ${METHODTIME} \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} + ${SLEEPTIME} \* 4 \* ${NUM_OF_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '$RESULTSDIR'"
(rm -rf ${RESULTSDIR}) && mkdir -p ${RESULTSDIR}
mkdir ${RESULTSDIR}stat/

# Clear inspectit.log and initialize logging
rm -f ${BASEDIR}inspectit.log
touch ${BASEDIR}inspectit.log

RAWFN="${RESULTSDIR}raw"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -Xms1G -Xmx2G"
JAVAARGS="${JAVAARGS} -verbose:gc "
JAR="-jar MooBench.jar --application moobench.application.MonitoredClassSimple"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASEDIR}agent/inspectit-ocelot-agent-1.11.1.jar -Djava.util.logging.config.file=${BASEDIR}config/logging.properties"
JAVAARGS_INSPECTIT_MINIMAL="${JAVAARGS_LTW} -Dinspectit.service-name=moobench-inspectit -Dinspectit.exporters.metrics.prometheus.enabled=false -Dinspectit.exporters.tracing.zipkin.url=http://127.0.0.1:9411/api/v2/spans -Dinspectit.config.file-based.path=${BASEDIR}config/zipkin/"
JAVAARGS_INSPECTIT_FULL="${JAVAARGS_LTW} -Dinspectit.config=${BASEDIR}config/timer/"

writeConfiguration

## Execute Benchmark
for ((i=1;i<=${NUM_OF_LOOPS};i+=1)); do
    k=0
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}"
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}" >>${BASEDIR}inspectit.log

    runNoInstrumentation
    cleanup

    runInspectITZipkin
    cleanup
    
    printIntermediaryResults
done
zip -jqr ${RESULTSDIR}stat.zip ${RESULTSDIR}stat
rm -rf ${RESULTSDIR}stat/
mv ${BASEDIR}inspectit.log ${RESULTSDIR}inspectit.log
[ -f ${RESULTSDIR}hotspot-1-${RECURSION_DEPTH}-1.log ] && grep "<task " ${RESULTSDIR}hotspot-*.log >${RESULTSDIR}log.log
[ -f ${BASEDIR}errorlog.txt ] && mv ${BASEDIR}errorlog.txt ${RESULTSDIR}

## Generate Results file
# Timeseries
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTSDIR}results-timeseries.pdf"
configs.loop=${NUM_OF_LOOPS}
configs.recursion=c(${RECURSION_DEPTH})
configs.labels=c("No Probe","InspectIT (minimal)","InspectIT (without CMR)","InspectIT (with CMR)")
configs.colors=c("black","red","blue","green")
results.count=${TOTALCALLS}
tsconf.min=(${METHODTIME}/1000)
tsconf.max=(${METHODTIME}/1000)+300
source("${RSCRIPTDIR}timeseries.r")
EOF
# Timeseries-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTSDIR}results-timeseries-average.pdf"
configs.loop=${NUM_OF_LOOPS}
configs.recursion=c(${RECURSION_DEPTH})
configs.labels=c("No Probe","InspectIT (minimal)","InspectIT (without CMR)","InspectIT (with CMR)")
configs.colors=c("black","red","blue","green")
results.count=${TOTALCALLS}
tsconf.min=(${METHODTIME}/1000)
tsconf.max=(${METHODTIME}/1000)+300
source("${RSCRIPTDIR}timeseries-average.r")
EOF
# Bars
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
outtxt_fn="${RESULTSDIR}results-text.txt"
configs.loop=${NUM_OF_LOOPS}
configs.recursion=c(${RECURSION_DEPTH})
configs.labels=c("No Probe","InspectIT (minimal)","InspectIT (without CMR)","InspectIT (with CMR)")
results.count=${TOTALCALLS}
results.skip=${TOTALCALLS}*3/4
source("${RSCRIPTDIR}stats.r")
EOF

## Clean up raw results
zip -jqr ${RESULTSDIR}results.zip ${RAWFN}*
rm -f ${RAWFN}*
[ -f ${BASEDIR}nohup.out ] && cp ${BASEDIR}nohup.out ${RESULTSDIR}
[ -f ${BASEDIR}nohup.out ] && > ${BASEDIR}nohup.out
