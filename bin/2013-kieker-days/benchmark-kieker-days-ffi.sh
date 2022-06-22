#!/bin/bash

JAVABIN="/localhome/ffi/jdk1.7.0_25/bin/"

R_SCRIPT_DIR=bin/icpe/r/
BASE_DIR=./
RESULTS_DIR="${BASE_DIR}tmp/results-benchmark-kieker-days-ffi/"

SLEEP_TIME=30            ## 30
NUM_LOOPS=1            ## 10
THREADS=1               ## 1
RECURSIONDEPTH=10       ## 10
TOTAL_CALLS=20000000     ## 20000000
METHODTIME=0            ## 0

MOREPARAMS=""
#MOREPARAMS="--quickstart"

TIME=`expr ${METHODTIME} \* ${TOTAL_CALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSIONDEPTH} + 50 \* ${TOTAL_CALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '${RESULTS_DIR}'"
(rm -rf ${RESULTS_DIR}) && mkdir ${RESULTS_DIR}
mkdir ${RESULTS_DIR}stat/

RAWFN="${RESULTS_DIR}raw"

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
JAVA_ARGS_LTW="${JAVA_ARGS} -javaagent:${BASE_DIR}lib/aspectjweaver.jar -Dorg.aspectj.weaver.showWeaveInfo=false -Daj.weaving.verbose=false -Dorg.aspectj.weaver.loadtime.configuration=META-INF/kieker-overhead-benchmark.aop.xml"

## Write configuration
uname -a >${RESULTS_DIR}configuration.txt
${JAVABIN}java ${JAVA_ARGS} -version 2>>${RESULTS_DIR}configuration.txt
echo "JAVA_ARGS: ${JAVA_ARGS}" >>${RESULTS_DIR}configuration.txt
echo "" >>${RESULTS_DIR}configuration.txt
echo "Runtime: circa ${TIME} seconds" >>${RESULTS_DIR}configuration.txt
echo "" >>${RESULTS_DIR}configuration.txt
echo "SLEEP_TIME=${SLEEP_TIME}" >>${RESULTS_DIR}configuration.txt
echo "NUM_LOOPS=${NUM_LOOPS}" >>${RESULTS_DIR}configuration.txt
echo "TOTAL_CALLS=${TOTAL_CALLS}" >>${RESULTS_DIR}configuration.txt
echo "METHODTIME=${METHODTIME}" >>${RESULTS_DIR}configuration.txt
echo "THREADS=${THREADS}" >>${RESULTS_DIR}configuration.txt
echo "RECURSIONDEPTH=${RECURSIONDEPTH}" >>${RESULTS_DIR}configuration.txt
sync

## Execute Benchmark

for ((i=1;i<=${NUM_LOOPS};i+=1)); do
    j=${RECURSIONDEPTH}
    k=0
    echo "## Starting iteration ${i}/${NUM_LOOPS}"

    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
	sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java  ${JAVA_ARGS_NOINSTR} ${JARNoInstru} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %sar
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEP_TIME}

    # Deactivated Probe
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Deactivated Probe"
	sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java -jar dist/explorviz_worker.jar >${RESULTS_DIR}worker-${i}-${j}-${k}.log &
    sleep 5
    ${JAVABIN}java  ${JAVA_ARGS_LTW} ${JARDeactived} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %sar
    pkill -f 'java -jar'
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEP_TIME}
	
    # Collecting
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Collecting"
	sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java -jar dist/explorviz_worker.jar >${RESULTS_DIR}worker-${i}-${j}-${k}.log &
    sleep 5
    ${JAVABIN}java  ${JAVA_ARGS_LTW} ${JARCollecting} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %sar
    pkill -f 'java -jar'
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEP_TIME}

    # Logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging"
	sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java -jar dist/explorviz_worker.jar >${RESULTS_DIR}worker-${i}-${j}-${k}.log &
    sleep 5
    ${JAVABIN}java  ${JAVA_ARGS_LTW} ${JARNORMAL} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %sar
    pkill -f 'java -jar'
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEP_TIME}
	
    # Reconstruction
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Reconstruction"
	sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java -jar dist/explorviz_workerReconstruction.jar >${RESULTS_DIR}worker-${i}-${j}-${k}.log &
    sleep 5
    ${JAVABIN}java  ${JAVA_ARGS_LTW} ${JARNORMAL} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %sar
    pkill -f 'java -jar'
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEP_TIME}

    # Reduction
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Reduction"
	sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java -jar dist/explorviz_workerReduction.jar >${RESULTS_DIR}worker-${i}-${j}-${k}.log &
    sleep 5
    ${JAVABIN}java  ${JAVA_ARGS_LTW} ${JARNORMAL} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %sar
    pkill -f 'java -jar'
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEP_TIME}
	
done
zip -jqr ${RESULTS_DIR}stat.zip ${RESULTS_DIR}stat
rm -rf ${RESULTS_DIR}stat/
[ -f ${RESULTS_DIR}hotspot-1-${RECURSIONDEPTH}-1.log ] && grep "<task " ${RESULTS_DIR}hotspot-*.log >${RESULTS_DIR}log.log
[ -f ${BASE_DIR}errorlog.txt ] && mv ${BASE_DIR}errorlog.txt ${RESULTS_DIR}

## Generate Results file
# Timeseries
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-timeseries.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTAL_CALLS}
tsconf.min=(${METHODTIME}/1000)
tsconf.max=(${METHODTIME}/1000)+40
source("${R_SCRIPT_DIR}timeseries.r")
EOF
# Timeseries-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-timeseries-average.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTAL_CALLS}
tsconf.min=(${METHODTIME}/1000)
tsconf.max=(${METHODTIME}/1000)+40
source("${R_SCRIPT_DIR}timeseries-average.r")
EOF
# Throughput
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-throughput.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTAL_CALLS}
source("${R_SCRIPT_DIR}throughput.r")
EOF
# Throughput-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-throughput-average.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTAL_CALLS}
source("${R_SCRIPT_DIR}throughput-average.r")
EOF
# Bars
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-bars.pdf"
outtxt_fn="${RESULTS_DIR}results-text.txt"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
results.count=${TOTAL_CALLS}
results.skip=${TOTAL_CALLS}/2
bars.minval=(${METHODTIME}/1000)
bars.maxval=(${METHODTIME}/1000)+40
source("${R_SCRIPT_DIR}bar.r")
EOF

## Clean up raw results
zip -jqr ${RESULTS_DIR}results.zip ${RAWFN}*
rm -f ${RAWFN}*
zip -jqr ${RESULTS_DIR}worker.zip ${RESULTS_DIR}worker*.log
rm -f ${RESULTS_DIR}worker*.log
[ -f ${BASE_DIR}nohup.out ] && mv ${BASE_DIR}nohup.out ${RESULTS_DIR}
