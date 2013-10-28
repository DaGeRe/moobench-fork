#!/bin/bash

JAVABIN=""
REMOTEHOST="ubuntu@10.50.0.4"
REMOTEBASEDIR="/home/ubuntu/"

RSCRIPTDIR=bin/r-scripts/
BASEDIR=./
RESULTSDIR="${BASEDIR}tmp/results-benchmark-kieker-days-ffi/"
REMOTERESULTSDIR="${REMOTEBASEDIR}tmp/results-benchmark-kieker-days-ffi/"

SLEEPTIME=30            ## 30
NUM_LOOPS=10            ## 10
THREADS=1               ## 1
RECURSIONDEPTH=10       ## 10
TOTALCALLS=100000000     ## 20000000
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

RAWFN="${RESULTSDIR}raw"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -d64"
JAVAARGS="${JAVAARGS} -Xms4G -Xmx12G"
JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JARNoInstru="-jar dist/OverheadEvaluationMicrobenchmarkTCPffiNoInstru.jar"
JARDeactived="-jar dist/OverheadEvaluationMicrobenchmarkTCPffiDeactivated.jar"
JARCollecting="-jar dist/OverheadEvaluationMicrobenchmarkTCPffiCollecting.jar"
JARNORMAL="-jar dist/OverheadEvaluationMicrobenchmarkTCPffiNormal.jar"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASEDIR}lib/aspectjweaver.jar -Dorg.aspectj.weaver.showWeaveInfo=false -Daj.weaving.verbose=false -Dorg.aspectj.weaver.loadtime.configuration=META-INF/kieker-overhead-benchmark.aop.xml"

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
    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
	#sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java  ${JAVAARGS_NOINSTR} ${JARNoInstru} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}

    # Deactivated Probe
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Deactivated Probe"
	#sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/explorviz_worker.jar </dev/null >${REMOTERESULTSDIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVAARGS_LTW} ${JARDeactived} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    killall java
	ssh ${REMOTEHOST} "killall java"
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}
	
    # Collecting
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Collecting"
	#sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/explorviz_worker.jar </dev/null >${REMOTERESULTSDIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVAARGS_LTW} ${JARCollecting} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    killall java
	ssh ${REMOTEHOST} "killall java"
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}

    # Logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging"
	#sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/explorviz_worker.jar </dev/null >${REMOTERESULTSDIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVAARGS_LTW} ${JARNORMAL} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    killall java
	ssh ${REMOTEHOST} "killall java"
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}
	
    # Reconstruction
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Reconstruction"
	#sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/explorviz_workerReconstruction.jar </dev/null >${REMOTERESULTSDIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVAARGS_LTW} ${JARNORMAL} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    killall java
	ssh ${REMOTEHOST} "killall java"
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}

    # Reduction
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Reduction"
	#sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/explorviz_workerReduction.jar </dev/null >${REMOTERESULTSDIR}worker-${i}-${j}-${k}.log 2>&1 &"
    sleep 5
    ${JAVABIN}java  ${JAVAARGS_LTW} ${JARNORMAL} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    killall java
	ssh ${REMOTEHOST} "killall java"
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}
	
done
zip -jqr ${RESULTSDIR}stat.zip ${RESULTSDIR}stat
rm -rf ${RESULTSDIR}stat/
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
