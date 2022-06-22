#!/bin/bash

JAVABIN=""
REMOTEHOST="ubuntu@10.50.0.7"
REMOTEBASEDIR="/home/ubuntu/"

R_SCRIPT_DIR=bin/r-scripts/
BASEDIR=./
RESULTS_DIR="${BASEDIR}tmp/results-benchmark-kieker-days-kieker/"
REMOTERESULTS_DIR="${REMOTEBASEDIR}tmp/results-benchmark-kieker-days-kieker/"

SLEEPTIME=30            ## 30
NUM_LOOPS=10            ## 10
THREADS=1               ## 1
RECURSIONDEPTH=10       ## 10
TOTALCALLS=4000000     ## 20000000
METHODTIME=0            ## 0

MOREPARAMS=""
#MOREPARAMS="--quickstart"

TIME=`expr ${METHODTIME} \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} + ${SLEEPTIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSIONDEPTH} + 50 \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '$RESULTS_DIR'"
(rm -rf ${RESULTS_DIR}) && mkdir ${RESULTS_DIR}
mkdir ${RESULTS_DIR}stat/

ssh ${REMOTEHOST} "(rm -rf ${REMOTERESULTS_DIR}) && mkdir ${REMOTERESULTS_DIR}"
ssh ${REMOTEHOST} "mkdir ${REMOTERESULTS_DIR}stat/"

# Clear kieker.log and initialize logging
rm -f ${BASEDIR}kieker.log
touch ${BASEDIR}kieker.log

RAWFN="${RESULTS_DIR}raw"

JAVA_ARGS="-server"
JAVA_ARGS="${JAVA_ARGS} -d64"
JAVA_ARGS="${JAVA_ARGS} -Xms4G -Xmx12G"
JAVA_ARGS="${JAVA_ARGS} -verbose:gc -XX:+PrintCompilation"
#JAVA_ARGS="${JAVA_ARGS} -XX:+PrintInlining"
#JAVA_ARGS="${JAVA_ARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVA_ARGS="${JAVA_ARGS} -Djava.compiler=NONE"
JAR="-jar dist/OverheadEvaluationMicrobenchmarkKieker.jar"

JAVA_ARGS_NOINSTR="${JAVA_ARGS}"
JAVA_ARGS_LTW="${JAVA_ARGS} -javaagent:${BASEDIR}lib/kieker-1.9-SNAPSHOT_aspectj.jar -Dorg.aspectj.weaver.showWeaveInfo=false -Daj.weaving.verbose=false -Dkieker.monitoring.adaptiveMonitoring.enabled=false -Dorg.aspectj.weaver.loadtime.configuration=META-INF/kieker.aop.xml"
JAVA_ARGS_KIEKER_DEACTV="${JAVA_ARGS_LTW} -Dkieker.monitoring.enabled=false -Dkieker.monitoring.writer=kieker.monitoring.writer.DummyWriter"
JAVA_ARGS_KIEKER_NOLOGGING="${JAVA_ARGS_LTW} -Dkieker.monitoring.writer=kieker.monitoring.writer.DummyWriter"
JAVA_ARGS_KIEKER_LOGGING="${JAVA_ARGS_LTW} -Dkieker.monitoring.writer=kieker.monitoring.writer.tcp.TCPWriter -Dkieker.monitoring.writer.tcp.TCPWriter.QueueSize=100000 -Dkieker.monitoring.writer.tcp.TCPWriter.hostname=10.50.0.7 -Dkieker.monitoring.writer.tcp.TCPWriter.QueueFullBehavior=1"

## Write configuration
uname -a >${RESULTS_DIR}configuration.txt
${JAVABIN}java ${JAVA_ARGS} -version 2>>${RESULTS_DIR}configuration.txt
echo "JAVA_ARGS: ${JAVA_ARGS}" >>${RESULTS_DIR}configuration.txt
echo "" >>${RESULTS_DIR}configuration.txt
echo "Runtime: circa ${TIME} seconds" >>${RESULTS_DIR}configuration.txt
echo "" >>${RESULTS_DIR}configuration.txt
echo "SLEEPTIME=${SLEEPTIME}" >>${RESULTS_DIR}configuration.txt
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
    echo "## Starting iteration ${i}/${NUM_LOOPS}" >>${BASEDIR}kieker.log

    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
    echo " # ${i}.${j}.${k} No instrumentation" >>${BASEDIR}kieker.log
    #sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java  ${JAVA_ARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}

    # Deactivated probe
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Deactivated probe"
    echo " # ${i}.${j}.${k} Deactivated probe" >>${BASEDIR}kieker.log
    #sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java  ${JAVA_ARGS_KIEKER_DEACTV} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}

    # No logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No logging (null writer)"
    echo " # ${i}.${j}.${k} No logging (null writer)" >>${BASEDIR}kieker.log
    #sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java  ${JAVA_ARGS_KIEKER_NOLOGGING} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}

    # Logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging"
    echo " # ${i}.${j}.${k} Logging" >>${BASEDIR}kieker.log
    #sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
	ssh ${REMOTEHOST} "${JAVABIN}java ${JAVA_ARGS} -jar ${REMOTEBASEDIR}dist/KiekerTCPReader1.jar </dev/null >${REMOTERESULTS_DIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVA_ARGS_KIEKER_LOGGING} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    killall java
	ssh ${REMOTEHOST} "killall java"
    rm -rf ${BASEDIR}tmp/kieker-*
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}

    # Reconstruction
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging"
    echo " # ${i}.${j}.${k} Logging" >>${BASEDIR}kieker.log
    #sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
	ssh ${REMOTEHOST} "${JAVABIN}java ${JAVA_ARGS} -jar ${REMOTEBASEDIR}dist/KiekerTCPReader2.jar </dev/null >${REMOTERESULTS_DIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVA_ARGS_KIEKER_LOGGING} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
	#kill %sar
    killall java
	ssh ${REMOTEHOST} "killall java"
    rm -rf ${BASEDIR}tmp/kieker-*
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}
	
    # Reduction
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging"
    echo " # ${i}.${j}.${k} Logging" >>${BASEDIR}kieker.log
    #sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
	ssh ${REMOTEHOST} "${JAVABIN}java ${JAVA_ARGS} -jar ${REMOTEBASEDIR}dist/KiekerTCPReader3.jar </dev/null >${REMOTERESULTS_DIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVA_ARGS_KIEKER_LOGGING} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
	#kill %sar
    killall java
	ssh ${REMOTEHOST} "killall java"
    rm -rf ${BASEDIR}tmp/kieker-*
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}
	
done
zip -jqr ${RESULTS_DIR}stat.zip ${RESULTS_DIR}stat
rm -rf ${RESULTS_DIR}stat/
mv ${BASEDIR}kieker.log ${RESULTS_DIR}kieker.log
[ -f ${RESULTS_DIR}hotspot-1-${RECURSIONDEPTH}-1.log ] && grep "<task " ${RESULTS_DIR}hotspot-*.log >${RESULTS_DIR}log.log
[ -f ${BASEDIR}errorlog.txt ] && mv ${BASEDIR}errorlog.txt ${RESULTS_DIR}

## Generate Results file
# Bars
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
outtxt_fn="${RESULTS_DIR}results-text.txt"
configs.threads=${THREADS}
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
results.count=${TOTALCALLS}
results.skip=${TOTALCALLS}/2
source("${R_SCRIPT_DIR}stats.r")
EOF

## Clean up raw results
zip -jqr ${RESULTS_DIR}results.zip ${RAWFN}*
rm -f ${RAWFN}*
zip -jqr ${RESULTS_DIR}worker.zip ${RESULTS_DIR}worker*.log
rm -f ${RESULTS_DIR}worker*.log
[ -f ${BASEDIR}nohup.out ] && mv ${BASEDIR}nohup.out ${RESULTS_DIR}
