#!/bin/bash

JAVABIN=""
REMOTEHOST="ubuntu@10.50.0.4"
REMOTEBASEDIR="/home/ubuntu/"

RSCRIPTDIR=bin/r-scripts/
BASEDIR=./
RESULTS_DIR="${BASEDIR}tmp/results-benchmark-kieker-days-ffi/"
REMOTERESULTS_DIR="${REMOTEBASEDIR}tmp/results-benchmark-kieker-days-ffi/"

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

echo "Removing and recreating '$RESULTS_DIR'"
(rm -rf ${RESULTS_DIR}) && mkdir ${RESULTS_DIR}
mkdir ${RESULTS_DIR}stat/

ssh ${REMOTEHOST} "(rm -rf ${REMOTERESULTS_DIR}) && mkdir ${REMOTERESULTS_DIR}"
ssh ${REMOTEHOST} "mkdir ${REMOTERESULTS_DIR}stat/"

RAWFN="${RESULTS_DIR}raw"

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
uname -a >${RESULTS_DIR}configuration.txt
${JAVABIN}java ${JAVAARGS} -version 2>>${RESULTS_DIR}configuration.txt
echo "JAVAARGS: ${JAVAARGS}" >>${RESULTS_DIR}configuration.txt
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
    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
	#sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java  ${JAVAARGS_NOINSTR} ${JARNoInstru} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}

    # Deactivated Probe
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Deactivated Probe"
	#sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/explorviz_worker.jar </dev/null >${REMOTERESULTS_DIR}worker-${i}-${j}-${k}.log 2>&1 &"
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
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}
	
    # Collecting
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Collecting"
	#sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/explorviz_worker.jar </dev/null >${REMOTERESULTS_DIR}worker-${i}-${j}-${k}.log 2>&1 &"
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
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}

    # Logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Logging"
	#sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/explorviz_worker.jar </dev/null >${REMOTERESULTS_DIR}worker-${i}-${j}-${k}.log 2>&1 &"
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
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}
	
    # Reconstruction
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Reconstruction"
	#sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/explorviz_workerReconstruction.jar </dev/null >${REMOTERESULTS_DIR}worker-${i}-${j}-${k}.log 2>&1 &"
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
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}

    # Reduction
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} Reduction"
	#sar -o ${RESULTS_DIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ssh ${REMOTEHOST} "${JAVABIN}java ${JAVAARGS} -jar ${REMOTEBASEDIR}dist/explorviz_workerReduction.jar </dev/null >${REMOTERESULTS_DIR}worker-${i}-${j}-${k}.log 2>&1 &"
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
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
    sync
    sleep ${SLEEPTIME}
	
done
zip -jqr ${RESULTS_DIR}stat.zip ${RESULTS_DIR}stat
rm -rf ${RESULTS_DIR}stat/
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
source("${RSCRIPTDIR}stats.r")
EOF

## Clean up raw results
zip -jqr ${RESULTS_DIR}results.zip ${RAWFN}*
rm -f ${RAWFN}*
zip -jqr ${RESULTS_DIR}worker.zip ${RESULTS_DIR}worker*.log
rm -f ${RESULTS_DIR}worker*.log
[ -f ${BASEDIR}nohup.out ] && mv ${BASEDIR}nohup.out ${RESULTS_DIR}
