#!/bin/bash

JAVABIN=""

RSCRIPTDIR=r/
BASEDIR=./
RESULTSDIR="${BASEDIR}tmp/results-inspectit-timer/"

SLEEPTIME=30           ## 30
NUM_LOOPS=10           ## 10
THREADS=1              ## 1
RECURSIONDEPTH=10      ## 10
TOTALCALLS=2000000     ## 2000000
METHODTIME=0           ## 0

#MOREPARAMS="--quickstart"
MOREPARAMS="${MOREPARAMS}"

TIME=`expr ${METHODTIME} \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} + ${SLEEPTIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSIONDEPTH} + 50 \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '$RESULTSDIR'"
(rm -rf ${RESULTSDIR}) && mkdir ${RESULTSDIR}
mkdir ${RESULTSDIR}stat/

# Clear inspectit.log and initialize logging
rm -f ${BASEDIR}inspectit.log
touch ${BASEDIR}inspectit.log
mkdir ${BASEDIR}logs/

RAWFN="${RESULTSDIR}raw"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -d64"
JAVAARGS="${JAVAARGS} -Xms1G -Xmx4G"
JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASEDIR}agent/inspectit-agent-mod.jar -Djava.util.logging.config.file=${BASEDIR}config/logging.properties -Dinspectit.config=${BASEDIR}config/timer/"
JAVAARGS_INSPECTIT_DISABLED="${JAVAARGS_LTW} -Dinspectit.disableProbe=true"
JAVAARGS_INSPECTIT_NOSTORAGE="${JAVAARGS_LTW} -Dinspectit.disableStorage=true"
JAVAARGS_INSPECTIT_FULL="${JAVAARGS_LTW}"

CMR_ARGS="-d64 -Xms12G -Xmx12G -Xmn4G -XX:MaxPermSize=128m -XX:PermSize=128m -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=80 -XX:+UseCMSInitiatingOccupancyOnly -XX:+UseParNewGC -XX:+CMSParallelRemarkEnabled -XX:+DisableExplicitGC -XX:SurvivorRatio=4 -XX:TargetSurvivorRatio=90 -XX:+AggressiveOpts -XX:+UseFastAccessorMethods -XX:+UseBiasedLocking -XX:+HeapDumpOnOutOfMemoryError -server -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -XX:+PrintTenuringDistribution -Dinspectit.logging.config=config/logging-config.xml"

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
    echo "## Starting iteration ${i}/${NUM_LOOPS}" >>${BASEDIR}inspectit.log

    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
    echo " # ${i}.${j}.${k} No instrumentation" >>${BASEDIR}inspectit.log
    sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}inspectit.log
    echo >>${BASEDIR}inspectit.log
    sync
    sleep ${SLEEPTIME}

    # InspectIT (disabled)
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} InspectIT (disabled)"
    echo " # ${i}.${j}.${k} InspectIT (disabled)" >>${BASEDIR}inspectit.log
    sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${CMR_ARGS} -Xloggc:${BASEDIR}logs/gc.log -jar CMR/inspectit-cmr-mod.jar 1>>${BASEDIR}logs/out.log 2>&1 &
    sleep 10
    ${JAVABIN}java ${JAVAARGS_INSPECTIT_DISABLED} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    sleep 10
    kill $!
    sleep 10
    rm -rf ${BASEDIR}storage/
    rm -rf ${BASEDIR}db/
    kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}inspectit.log
    echo >>${BASEDIR}inspectit.log
    sync
    sleep ${SLEEPTIME}

    # InspectIT (no storage)
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} InspectIT (no storage)"
    echo " # ${i}.${j}.${k} InspectIT (no storage)" >>${BASEDIR}inspectit.log
    sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${CMR_ARGS} -Xloggc:${BASEDIR}logs/gc.log -jar CMR/inspectit-cmr-mod.jar 1>>${BASEDIR}logs/out.log 2>&1 &
    sleep 10
    ${JAVABIN}java ${JAVAARGS_INSPECTIT_NOSTORAGE} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    sleep 10
    kill $!
    sleep 10
    rm -rf ${BASEDIR}storage/
    rm -rf ${BASEDIR}db/
    kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}inspectit.log
    echo >>${BASEDIR}inspectit.log
    sync
    sleep ${SLEEPTIME}
    
    # InspectIT (full)
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} InspectIT (full)"
    echo " # ${i}.${j}.${k} InspectIT (full)" >>${BASEDIR}inspectit.log
    sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${CMR_ARGS} -Xloggc:${BASEDIR}logs/gc.log -jar CMR/inspectit-cmr-mod.jar 1>>${BASEDIR}logs/out.log 2>&1 &
    sleep 10
    ${JAVABIN}java ${JAVAARGS_INSPECTIT_FULL} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    sleep 10
    kill $!
    sleep 10
    rm -rf ${BASEDIR}storage/
    rm -rf ${BASEDIR}db/
    kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}inspectit.log
    echo >>${BASEDIR}inspectit.log
    sync
    sleep ${SLEEPTIME}

done
zip -jqr ${RESULTSDIR}stat.zip ${RESULTSDIR}stat
rm -rf ${RESULTSDIR}stat/
mv ${BASEDIR}logs/ ${RESULTSDIR}
mv ${BASEDIR}inspectit.log ${RESULTSDIR}inspectit.log
[ -f ${RESULTSDIR}hotspot-1-${RECURSIONDEPTH}-1.log ] && grep "<task " ${RESULTSDIR}hotspot-*.log >${RESULTSDIR}log.log
[ -f ${BASEDIR}errorlog.txt ] && mv ${BASEDIR}errorlog.txt ${RESULTSDIR}

## Generate Results file
# Timeseries
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTSDIR}results-timeseries.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","InspectIT (disabled)","InspectIT (no storage)","InspectIT (full)")
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
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","InspectIT (disabled)","InspectIT (no storage)","InspectIT (full)")
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
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","InspectIT (disabled)","InspectIT (no storage)","InspectIT (full)")
results.count=${TOTALCALLS}
results.skip=${TOTALCALLS}*3/4
source("${RSCRIPTDIR}stats.r")
EOF

## Clean up raw results
zip -jqr ${RESULTSDIR}results.zip ${RAWFN}*
rm -f ${RAWFN}*
[ -f ${BASEDIR}nohup.out ] && cp ${BASEDIR}nohup.out ${RESULTSDIR}
[ -f ${BASEDIR}nohup.out ] && > ${BASEDIR}nohup.out
