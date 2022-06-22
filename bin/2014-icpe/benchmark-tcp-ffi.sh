#!/bin/bash

JAVA_BIN="/localhome/ffi/jdk1.7.0_25/bin/java"

R_SCRIPT_DIR=bin/icpe/r
BASE_DIR=.
RESULTS_DIR="${BASE_DIR}/tmp/results-benchmark-tcp-ffi/"

SLEEP_TIME=30            ## 30
NUM_LOOPS=10            ## 10
THREADS=1               ## 1
RECURSION_DEPTH=10       ## 10
TOTAL_CALLS=20000000     ## 20000000
METHOD_TIME=0            ## 0

MORE_PARAMS=""
#MORE_PARAMS="--quickstart"

TIME=`expr ${METHOD_TIME} \* ${TOTAL_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTAL_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '${RESULTS_DIR}'"
(rm -rf "${RESULTS_DIR}") && mkdir "${RESULTS_DIR}"
mkdir "${RESULTS_DIR}/stat"

RAWFN="${RESULTS_DIR}/raw"

JAVA_ARGS="-server"
JAVA_ARGS="${JAVA_ARGS} -d64"
JAVA_ARGS="${JAVA_ARGS} -Xms1G -Xmx4G"
JAVA_ARGS="${JAVA_ARGS} -verbose:gc -XX:+PrintCompilation"
#JAVA_ARGS="${JAVA_ARGS} -XX:+PrintInlining"
#JAVA_ARGS="${JAVA_ARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVA_ARGS="${JAVA_ARGS} -Djava.compiler=NONE"
JARNoInstru="-jar dist/OverheadEvaluationMicrobenchmarkTCPffiNoInstru.jar"
JARDeactived="-jar dist/OverheadEvaluationMicrobenchmarkTCPffiDeactivated.jar"
JARCollecting="-jar dist/OverheadEvaluationMicrobenchmarkTCPffiCollecting.jar"
JARNORMAL="-jar dist/OverheadEvaluationMicrobenchmarkTCPffiNormal.jar"

JAVA_ARGS_NOINSTR="${JAVA_ARGS}"
JAVA_ARGS_LTW="${JAVA_ARGS} -javaagent:${BASE_DIR}/lib/aspectjweaver.jar -Dorg.aspectj.weaver.showWeaveInfo=false -Daj.weaving.verbose=false"

## Write configuration
uname -a >${RESULTS_DIR}/configuration.txt
${JAVA_BIN} ${JAVA_ARGS} -version 2 >> "${RESULTS_DIR}/configuration.txt"
echo "JAVA_ARGS: ${JAVA_ARGS}" >> "${RESULTS_DIR}/configuration.txt"
echo "" >> "${RESULTS_DIR}/configuration.txt"
echo "Runtime: circa ${TIME} seconds" >> "${RESULTS_DIR}/configuration.txt"
echo "" >> "${RESULTS_DIR}/configuration.txt"
echo "SLEEP_TIME=${SLEEP_TIME}" >> "${RESULTS_DIR}/configuration.txt"
echo "NUM_LOOPS=${NUM_LOOPS}" >> "${RESULTS_DIR}/configuration.txt"
echo "TOTAL_CALLS=${TOTAL_CALLS}" >> "${RESULTS_DIR}/configuration.txt"
echo "METHOD_TIME=${METHOD_TIME}" >> "${RESULTS_DIR}/configuration.txt"
echo "THREADS=${THREADS}" >> "${RESULTS_DIR}/configuration.txt"
echo "RECURSION_DEPTH=${RECURSION_DEPTH}" >> "${RESULTS_DIR}/configuration.txt"
sync

## Execute Benchmark

for ((i=1;i<=${NUM_LOOPS};i+=1)); do
    j=${RECURSION_DEPTH}
    k=0
    echo "## Starting iteration ${i}/${NUM_LOOPS}"

    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
    mpstat 1 > ${RESULTS_DIR}/stat/mpstat-${i}-${j}-${k}.txt &
    vmstat 1 > ${RESULTS_DIR}/stat/vmstat-${i}-${j}-${k}.txt &
    iostat -xn 10 > ${RESULTS_DIR}/stat/iostat-${i}-${j}-${k}.txt &
    ${JAVA_BIN}  ${JAVA_ARGS_NOINSTR} ${JARNoInstru} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTAL_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MORE_PARAMS}
    kill %mpstat
    kill %vmstat
    kill %iostat
    [ -f ${BASE_DIR}/hotspot.log ] && mv ${BASE_DIR}/hotspot.log ${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEP_TIME}

    # Deactivated Probe
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Deactivated Probe"
    mpstat 1 > ${RESULTS_DIR}/stat/mpstat-${i}-${j}-${k}.txt &
    vmstat 1 > ${RESULTS_DIR}/stat/vmstat-${i}-${j}-${k}.txt &
    iostat -xn 10 > ${RESULTS_DIR}/stat/iostat-${i}-${j}-${k}.txt &
    ${JAVA_BIN} -jar dist/explorviz_worker.jar >${RESULTS_DIR}/worker-${i}-${j}-${k}.log &
    sleep 5
    ${JAVA_BIN}  ${JAVA_ARGS_LTW} ${JARDeactived} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTAL_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MORE_PARAMS}
    kill %mpstat
    kill %vmstat
    kill %iostat
    pkill -f 'java -jar'
    rm -rf ${BASE_DIR}/tmp/kieker-*
    [ -f ${BASE_DIR}/hotspot.log ] && mv ${BASE_DIR}/hotspot.log ${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEP_TIME}
	
    # Collecting
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Collecting"
    mpstat 1 > ${RESULTS_DIR}/stat/mpstat-${i}-${j}-${k}.txt &
    vmstat 1 > ${RESULTS_DIR}/stat/vmstat-${i}-${j}-${k}.txt &
    iostat -xn 10 > ${RESULTS_DIR}/stat/iostat-${i}-${j}-${k}.txt &
    ${JAVA_BIN} -jar dist/explorviz_worker.jar >${RESULTS_DIR}/worker-${i}-${j}-${k}.log &
    sleep 5
    ${JAVA_BIN}  ${JAVA_ARGS_LTW} ${JARCollecting} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTAL_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MORE_PARAMS}
    kill %mpstat
    kill %vmstat
    kill %iostat
    pkill -f 'java -jar'
    rm -rf ${BASE_DIR}/tmp/kieker-*
    [ -f ${BASE_DIR}/hotspot.log ] && mv ${BASE_DIR}/hotspot.log ${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEP_TIME}

    # Logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging"
    mpstat 1 > ${RESULTS_DIR}/stat/mpstat-${i}-${j}-${k}.txt &
    vmstat 1 > ${RESULTS_DIR}/stat/vmstat-${i}-${j}-${k}.txt &
    iostat -xn 10 > ${RESULTS_DIR}/stat/iostat-${i}-${j}-${k}.txt &
    ${JAVA_BIN} -jar dist/explorviz_worker.jar >${RESULTS_DIR}/worker-${i}-${j}-${k}.log &
    sleep 5
    ${JAVA_BIN}  ${JAVA_ARGS_LTW} ${JARNORMAL} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTAL_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MORE_PARAMS}
    kill %mpstat
    kill %vmstat
    kill %iostat
    pkill -f 'java -jar'
    rm -rf ${BASE_DIR}/tmp/kieker-*
    [ -f ${BASE_DIR}/hotspot.log ] && mv ${BASE_DIR}/hotspot.log ${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEP_TIME}

done
zip -jqr ${RESULTS_DIR}/stat.zip ${RESULTS_DIR}/stat
rm -rf ${RESULTS_DIR}/stat/
[ -f ${RESULTS_DIR}/hotspot-1-${RECURSION_DEPTH}-1.log ] && grep "<task " ${RESULTS_DIR}/hotspot-*.log >${RESULTS_DIR}/log.log
[ -f ${BASE_DIR}/errorlog.txt ] && mv ${BASE_DIR}/errorlog.txt ${RESULTS_DIR}/

## Generate Results file
# Timeseries
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}/results-timeseries.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSION_DEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer")
configs.colors=c("black","red","blue","green")
results.count=${TOTAL_CALLS}
tsconf.min=(${METHOD_TIME}/1000)
tsconf.max=(${METHOD_TIME}/1000)+40
source("${R_SCRIPT_DIR}timeseries.r")
EOF
# Timeseries-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}/results-timeseries-average.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSION_DEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer")
configs.colors=c("black","red","blue","green")
results.count=${TOTAL_CALLS}
tsconf.min=(${METHOD_TIME}/1000)
tsconf.max=(${METHOD_TIME}/1000)+40
source("${R_SCRIPT_DIR}timeseries-average.r")
EOF
# Throughput
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}/results-throughput.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSION_DEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer")
configs.colors=c("black","red","blue","green")
results.count=${TOTAL_CALLS}
source("${R_SCRIPT_DIR}throughput.r")
EOF
# Throughput-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}/results-throughput-average.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSION_DEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer")
configs.colors=c("black","red","blue","green")
results.count=${TOTAL_CALLS}
source("${R_SCRIPT_DIR}throughput-average.r")
EOF
# Bars
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}/results-bars.pdf"
outtxt_fn="${RESULTS_DIR}/results-text.txt"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSION_DEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer")
results.count=${TOTAL_CALLS}
results.skip=${TOTAL_CALLS}/2
bars.minval=(${METHOD_TIME}/1000)
bars.maxval=(${METHOD_TIME}/1000)+40
source("${R_SCRIPT_DIR}bar.r")
EOF

## Clean up raw results
zip -jqr ${RESULTS_DIR}/results.zip ${RAWFN}*
rm -f ${RAWFN}*
zip -jqr ${RESULTS_DIR}/worker.zip ${RESULTS_DIR}/worker*.log
rm -f ${RESULTS_DIR}/worker*.log
[ -f ${BASE_DIR}/nohup.out ] && mv ${BASE_DIR}/nohup.out ${RESULTS_DIR}/
