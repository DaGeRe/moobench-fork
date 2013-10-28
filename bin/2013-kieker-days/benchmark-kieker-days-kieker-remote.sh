#!/bin/bash

JAVABIN=""
REMOTEHOST="ubuntu@10.50.0.7"
REMOTEBASEDIR="/home/ubuntu/"

RSCRIPTDIR=bin/r-scripts/
BASEDIR=./
RESULTSDIR="${BASEDIR}tmp/results-benchmark-kieker-days-kieker/"
REMOTERESULTSDIR="${REMOTEBASEDIR}tmp/results-benchmark-kieker-days-kieker/"

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

echo "Removing and recreating '$RESULTSDIR'"
(rm -rf ${RESULTSDIR}) && mkdir ${RESULTSDIR}
mkdir ${RESULTSDIR}stat/

ssh ${REMOTEHOST} "(rm -rf ${REMOTERESULTSDIR}) && mkdir ${REMOTERESULTSDIR}"
ssh ${REMOTEHOST} "mkdir ${REMOTERESULTSDIR}stat/"

# Clear kieker.log and initialize logging
rm -f ${BASEDIR}kieker.log
touch ${BASEDIR}kieker.log

RAWFN="${RESULTSDIR}raw"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -d64"
JAVAARGS="${JAVAARGS} -Xms4G -Xmx12G"
JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JAR="-jar dist/OverheadEvaluationMicrobenchmarkKieker.jar"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASEDIR}lib/kieker-1.9-SNAPSHOT_aspectj.jar -Dorg.aspectj.weaver.showWeaveInfo=false -Daj.weaving.verbose=false -Dkieker.monitoring.adaptiveMonitoring.enabled=false -Dorg.aspectj.weaver.loadtime.configuration=META-INF/kieker.aop.xml"
JAVAARGS_KIEKER_DEACTV="${JAVAARGS_LTW} -Dkieker.monitoring.enabled=false -Dkieker.monitoring.writer=kieker.monitoring.writer.DummyWriter"
JAVAARGS_KIEKER_NOLOGGING="${JAVAARGS_LTW} -Dkieker.monitoring.writer=kieker.monitoring.writer.DummyWriter"
JAVAARGS_KIEKER_LOGGING="${JAVAARGS_LTW} -Dkieker.monitoring.writer=kieker.monitoring.writer.tcp.TCPWriter -Dkieker.monitoring.writer.tcp.TCPWriter.QueueSize=100000 -Dkieker.monitoring.writer.tcp.TCPWriter.hostname=10.50.0.7 -Dkieker.monitoring.writer.tcp.TCPWriter.QueueFullBehavior=1"

## Write configuration
uname -a >${RESULTSDIR}configuration.txt
${JAVABIN}java ${JAVAARGS} -version 2>>${RESULTSDIR}configuration.txt
echo "JAVAARGS: ${JAVAARGS}" >>${RESULTSDIR}configuration.txt
echo "" >>${RESULTSDIR}configuration.txt
echo "Runtime: circa ${TIME} seconds" >>${RESULTSDIR}configuration.txt
echo "" >>${RESULTSDIR}configuration.txt
echo "SLEEPTIME=${SLEEPTIME}" >>${RESULTSDIR}configuration.txt
echo "NUM_LOOPS=${NUM_LOOPS}" >>${RESULTSDIR}configuration.txt
echo "TOTALCALLS=${TOTALCALLS}" >>${RESULTSDIR}configuration.txt
echo "METHODTIME=${METHODTIME}" >>${RESULTSDIR}configuration.txt
echo "THREADS=${THREADS}" >>${RESULTSDIR}configuration.txt
echo "RECURSIONDEPTH=${RECURSIONDEPTH}" >>${RESULTSDIR}configuration.txt
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
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java  ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}

    # Deactivated probe
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Deactivated probe"
    echo " # ${i}.${j}.${k} Deactivated probe" >>${BASEDIR}kieker.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java  ${JAVAARGS_KIEKER_DEACTV} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}

    # No logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No logging (null writer)"
    echo " # ${i}.${j}.${k} No logging (null writer)" >>${BASEDIR}kieker.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java  ${JAVAARGS_KIEKER_NOLOGGING} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}

    # Logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging"
    echo " # ${i}.${j}.${k} Logging" >>${BASEDIR}kieker.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
	ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/KiekerTCPReader1.jar </dev/null >${REMOTERESULTSDIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVAARGS_KIEKER_LOGGING} ${JAR} \
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
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}

    # Reconstruction
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging"
    echo " # ${i}.${j}.${k} Logging" >>${BASEDIR}kieker.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
	ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/KiekerTCPReader2.jar </dev/null >${REMOTERESULTSDIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVAARGS_KIEKER_LOGGING} ${JAR} \
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
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}
	
    # Reduction
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging"
    echo " # ${i}.${j}.${k} Logging" >>${BASEDIR}kieker.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
	ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/KiekerTCPReader3.jar </dev/null >${REMOTERESULTSDIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVAARGS_KIEKER_LOGGING} ${JAR} \
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
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}kieker.log
    echo >>${BASEDIR}kieker.log
    sync
    sleep ${SLEEPTIME}
	
done
zip -jqr ${RESULTSDIR}stat.zip ${RESULTSDIR}stat
rm -rf ${RESULTSDIR}stat/
mv ${BASEDIR}kieker.log ${RESULTSDIR}kieker.log
[ -f ${RESULTSDIR}hotspot-1-${RECURSIONDEPTH}-1.log ] && grep "<task " ${RESULTSDIR}hotspot-*.log >${RESULTSDIR}log.log
[ -f ${BASEDIR}errorlog.txt ] && mv ${BASEDIR}errorlog.txt ${RESULTSDIR}

## Generate Results file
# Bars
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
outtxt_fn="${RESULTSDIR}results-text.txt"
configs.threads=${THREADS}
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
results.count=${TOTALCALLS}
results.skip=${TOTALCALLS}/2
source("${RSCRIPTDIR}stats.r")
EOF

## Clean up raw results
zip -jqr ${RESULTSDIR}results.zip ${RAWFN}*
rm -f ${RAWFN}*
zip -jqr ${RESULTSDIR}worker.zip ${RESULTSDIR}worker*.log
rm -f ${RESULTSDIR}worker*.log
[ -f ${BASEDIR}nohup.out ] && mv ${BASEDIR}nohup.out ${RESULTSDIR}
