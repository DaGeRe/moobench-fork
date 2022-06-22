#!/bin/bash

JAVABIN="/localhome/ffi/jdk1.7.0_25/bin/"

R_SCRIPT_DIR=bin/icpe/r/
BASE_DIR=./
RESULTS_DIR="${BASE_DIR}tmp/results-benchmark-disk/"

SLEEP_TIME=30            ## 30
NUM_LOOPS=10            ## 10
THREADS=1               ## 1
RECURSIONDEPTH=10       ## 10
TOTALCALLS=2000000      ## 2000000
METHODTIME=0            ## 0

MOREPARAMS=""
#MOREPARAMS="--quickstart"

TIME=`expr ${METHODTIME} \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSIONDEPTH} + 50 \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '${RESULTS_DIR}'"
(rm -rf ${RESULTS_DIR}) && mkdir ${RESULTS_DIR}
mkdir ${RESULTS_DIR}stat/

# Clear kieker.log and initialize logging
rm -f ${BASE_DIR}kieker.log
touch ${BASE_DIR}kieker.log

RAWFN="${RESULTS_DIR}raw"

JAVA_ARGS="-server"
JAVA_ARGS="${JAVA_ARGS} -d64"
JAVA_ARGS="${JAVA_ARGS} -Xms1G -Xmx4G"
JAVA_ARGS="${JAVA_ARGS} -verbose:gc -XX:+PrintCompilation"
#JAVA_ARGS="${JAVA_ARGS} -XX:+PrintInlining"
#JAVA_ARGS="${JAVA_ARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVA_ARGS="${JAVA_ARGS} -Djava.compiler=NONE"
JAR="-jar dist/OverheadEvaluationMicrobenchmarkKieker.jar"

JAVA_ARGS_NOINSTR="${JAVA_ARGS}"
JAVA_ARGS_LTW="${JAVA_ARGS} -javaagent:${BASE_DIR}lib/kieker-1.8-SNAPSHOT_aspectj.jar -Dorg.aspectj.weaver.showWeaveInfo=false -Daj.weaving.verbose=false -Dkieker.monitoring.adaptiveMonitoring.enabled=false -Dorg.aspectj.weaver.loadtime.configuration=META-INF/kieker.aop.xml"
JAVA_ARGS_KIEKER_DEACTV="${JAVA_ARGS_LTW} -Dkieker.monitoring.enabled=false -Dkieker.monitoring.writer=kieker.monitoring.writer.DummyWriter"
JAVA_ARGS_KIEKER_NOLOGGING="${JAVA_ARGS_LTW} -Dkieker.monitoring.writer=kieker.monitoring.writer.DummyWriter"
JAVA_ARGS_KIEKER_LOGGING1="${JAVA_ARGS_LTW} -Dkieker.monitoring.writer=kieker.monitoring.writer.filesystem.AsyncBinaryFsWriter -Dkieker.monitoring.writer.filesystem.AsyncBinaryFsWriter.customStoragePath=${BASE_DIR}tmp -Dkieker.monitoring.writer.filesystem.AsyncBinaryFsWriter.QueueFullBehavior=1"
JAVA_ARGS_KIEKER_LOGGING2="${JAVA_ARGS_LTW} -Dkieker.monitoring.writer=kieker.monitoring.writer.filesystem.AsyncBinaryZipWriter -Dkieker.monitoring.writer.filesystem.AsyncBinaryZipWriter.customStoragePath=${BASE_DIR}tmp -Dkieker.monitoring.writer.filesystem.AsyncBinaryZipWriter.QueueFullBehavior=1"
JAVA_ARGS_KIEKER_LOGGING3="${JAVA_ARGS_LTW} -Dkieker.monitoring.writer=kieker.monitoring.writer.filesystem.AsyncFsWriter -Dkieker.monitoring.writer.filesystem.AsyncFsWriter.customStoragePath=${BASE_DIR}tmp -Dkieker.monitoring.writer.filesystem.AsyncFsWriter.QueueFullBehavior=1"

## Write configuration
uname -a >${RESULTS_DIR}configuration.txt
${JAVABIN}java ${JAVA_ARGS} -version 2>>${RESULTS_DIR}configuration.txt
echo "JAVA_ARGS: ${JAVA_ARGS}" >>${RESULTS_DIR}configuration.txt
echo "" >>${RESULTS_DIR}configuration.txt
echo "Runtime: circa ${TIME} seconds" >>${RESULTS_DIR}configuration.txt
echo "" >>${RESULTS_DIR}configuration.txt
echo "SLEEP_TIME=${SLEEP_TIME}" >>${RESULTS_DIR}configuration.txt
echo "NUM_LOOPS=${NUM_LOOPS}" >>${RESULTS_DIR}configuration.txt
echo "TOTALCALLS=${TOTALCALLS}" >>${RESULTS_DIR}configuration.txt
echo "METHODTIME=${METHODTIME}" >>${RESULTS_DIR}configuration.txt
echo "THREADS=${THREADS}" >>${RESULTS_DIR}configuration.txt
echo "RECURSIONDEPTH=${RECURSIONDEPTH}" >>${RESULTS_DIR}configuration.txt
sync

## Execute Benchmark
for ((i=1;i<=${NUM_LOOPS};i+=1)); do
    j=${RECURSIONDEPTH}
    k=0
    echo "## Starting iteration ${i}/${NUM_LOOPS}"
    echo "## Starting iteration ${i}/${NUM_LOOPS}" >>${BASE_DIR}kieker.log

    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
    echo " # ${i}.${j}.${k} No instrumentation" >>${BASE_DIR}kieker.log
    mpstat 1 > ${RESULTS_DIR}stat/mpstat-${i}-${j}-${k}.txt &
    vmstat 1 > ${RESULTS_DIR}stat/vmstat-${i}-${j}-${k}.txt &
    iostat -xn 10 > ${RESULTS_DIR}stat/iostat-${i}-${j}-${k}.txt &
    ${JAVABIN}java  ${JAVA_ARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %mpstat
    kill %vmstat
    kill %iostat
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASE_DIR}kieker.log
    echo >>${BASE_DIR}kieker.log
    sync
    sleep ${SLEEP_TIME}

    # Deactivated probe
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Deactivated probe"
    echo " # ${i}.${j}.${k} Deactivated probe" >>${BASE_DIR}kieker.log
    mpstat 1 > ${RESULTS_DIR}stat/mpstat-${i}-${j}-${k}.txt &
    vmstat 1 > ${RESULTS_DIR}stat/vmstat-${i}-${j}-${k}.txt &
    iostat -xn 10 > ${RESULTS_DIR}stat/iostat-${i}-${j}-${k}.txt &
    ${JAVABIN}java  ${JAVA_ARGS_KIEKER_DEACTV} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %mpstat
    kill %vmstat
    kill %iostat
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASE_DIR}kieker.log
    echo >>${BASE_DIR}kieker.log
    sync
    sleep ${SLEEP_TIME}

    # No logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No logging (null writer)"
    echo " # ${i}.${j}.${k} No logging (null writer)" >>${BASE_DIR}kieker.log
    mpstat 1 > ${RESULTS_DIR}stat/mpstat-${i}-${j}-${k}.txt &
    vmstat 1 > ${RESULTS_DIR}stat/vmstat-${i}-${j}-${k}.txt &
    iostat -xn 10 > ${RESULTS_DIR}stat/iostat-${i}-${j}-${k}.txt &
    ${JAVABIN}java  ${JAVA_ARGS_KIEKER_NOLOGGING} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %mpstat
    kill %vmstat
    kill %iostat
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASE_DIR}kieker.log
    echo >>${BASE_DIR}kieker.log
    sync
    sleep ${SLEEP_TIME}

    # Logging 1
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging 1"
    echo " # ${i}.${j}.${k} Logging 1" >>${BASE_DIR}kieker.log
    mpstat 1 > ${RESULTS_DIR}stat/mpstat-${i}-${j}-${k}.txt &
    vmstat 1 > ${RESULTS_DIR}stat/vmstat-${i}-${j}-${k}.txt &
    iostat -xn 10 > ${RESULTS_DIR}stat/iostat-${i}-${j}-${k}.txt &
    ${JAVABIN}java  ${JAVA_ARGS_KIEKER_LOGGING1} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %mpstat
    kill %vmstat
    kill %iostat
    rm -rf ${BASE_DIR}tmp/kieker-*
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASE_DIR}kieker.log
    echo >>${BASE_DIR}kieker.log
    sync
    sleep ${SLEEP_TIME}

    # Logging 2
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging 2"
    echo " # ${i}.${j}.${k} Logging 2" >>${BASE_DIR}kieker.log
    mpstat 1 > ${RESULTS_DIR}stat/mpstat-${i}-${j}-${k}.txt &
    vmstat 1 > ${RESULTS_DIR}stat/vmstat-${i}-${j}-${k}.txt &
    iostat -xn 10 > ${RESULTS_DIR}stat/iostat-${i}-${j}-${k}.txt &
    ${JAVABIN}java  ${JAVA_ARGS_KIEKER_LOGGING2} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %mpstat
    kill %vmstat
    kill %iostat
    rm -rf ${BASE_DIR}tmp/kieker-*
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASE_DIR}kieker.log
    echo >>${BASE_DIR}kieker.log
    sync
    sleep ${SLEEP_TIME}

    # Logging 3
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging 3"
    echo " # ${i}.${j}.${k} Logging 3" >>${BASE_DIR}kieker.log
    mpstat 1 > ${RESULTS_DIR}stat/mpstat-${i}-${j}-${k}.txt &
    vmstat 1 > ${RESULTS_DIR}stat/vmstat-${i}-${j}-${k}.txt &
    iostat -xn 10 > ${RESULTS_DIR}stat/iostat-${i}-${j}-${k}.txt &
    ${JAVABIN}java  ${JAVA_ARGS_KIEKER_LOGGING3} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %mpstat
    kill %vmstat
    kill %iostat
    rm -rf ${BASE_DIR}tmp/kieker-*
    [ -f ${BASE_DIR}hotspot.log ] && mv ${BASE_DIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASE_DIR}kieker.log
    echo >>${BASE_DIR}kieker.log
    sync
    sleep ${SLEEP_TIME}

done
zip -jqr ${RESULTS_DIR}stat.zip ${RESULTS_DIR}stat
rm -rf ${RESULTS_DIR}stat/
mv ${BASE_DIR}kieker.log ${RESULTS_DIR}kieker.log
[ -f ${RESULTS_DIR}hotspot-1-${RECURSIONDEPTH}-1.log ] && grep "<task " ${RESULTS_DIR}hotspot-*.log >${RESULTS_DIR}log.log
[ -f ${BASE_DIR}errorlog.txt ] && mv ${BASE_DIR}errorlog.txt ${RESULTS_DIR}

## Generate Results file
# Timeseries
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-timeseries.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","Writer1","Writer2","Writer3")
configs.colors=c("black","red","blue","green","purple","pink")
results.count=${TOTALCALLS}
tsconf.min=(${METHODTIME}/1000)
tsconf.max=(${METHODTIME}/1000)+200
source("${R_SCRIPT_DIR}timeseries.r")
EOF
# Timeseries-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-timeseries-average.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","Writer1","Writer2","Writer3")
configs.colors=c("black","red","blue","green","purple","pink")
results.count=${TOTALCALLS}
tsconf.min=(${METHODTIME}/1000)
tsconf.max=(${METHODTIME}/1000)+200
source("${R_SCRIPT_DIR}timeseries-average.r")
EOF
# Throughput
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-throughput.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","Writer1","Writer2","Writer3")
configs.colors=c("black","red","blue","green","purple","pink")
results.count=${TOTALCALLS}
source("${R_SCRIPT_DIR}throughput.r")
EOF
# Throughput-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-throughput-average.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","Writer1","Writer2","Writer3")
configs.colors=c("black","red","blue","green","purple","pink")
results.count=${TOTALCALLS}
source("${R_SCRIPT_DIR}throughput-average.r")
EOF
# Bars
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-bars.pdf"
outtxt_fn="${RESULTS_DIR}results-text.txt"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","Writer1","Writer2","Writer3")
results.count=${TOTALCALLS}
results.skip=${TOTALCALLS}/2
bars.minval=(${METHODTIME}/1000)
bars.maxval=(${METHODTIME}/1000)+200
source("${R_SCRIPT_DIR}bar.r")
EOF

## Clean up raw results
zip -jqr ${RESULTS_DIR}results.zip ${RAWFN}*
rm -f ${RAWFN}*
[ -f ${BASE_DIR}nohup.out ] && mv ${BASE_DIR}nohup.out ${RESULTS_DIR}
