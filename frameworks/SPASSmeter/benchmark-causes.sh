#!/bin/bash
# This file is configured for linux instead of solaris!!!

JAVABIN=""

RSCRIPTDIR=r/
BASEDIR=./
RESULTSDIR="${BASEDIR}tmp/results-spassmeter/"

SLEEPTIME=30           ## 30
NUM_LOOPS=10           ## 10
THREADS=1              ## 1
RECURSIONDEPTH=10      ## 10
TOTALCALLS=2000000     ## 2000000
METHODTIME=0      ## 500000

#MOREPARAMS="--quickstart"
MOREPARAMS="--application mooBench.monitoredApplication.MonitoredClassSimple ${MOREPARAMS}"

TIME=`expr ${METHODTIME} \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} + ${SLEEPTIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSIONDEPTH} + 50 \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '$RESULTSDIR'"
(rm -rf ${RESULTSDIR}) && mkdir ${RESULTSDIR}
#mkdir ${RESULTSDIR}stat/

# Clear spassmeter.log and initialize logging
rm -f ${BASEDIR}spassmeter.log
touch ${BASEDIR}spassmeter.log

RAWFN="${RESULTSDIR}raw"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -d64"
JAVAARGS="${JAVAARGS} -Xms1G -Xmx12G"
JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASEDIR}lib/linux/spass-meter-ia.jar=xmlconfig=${BASEDIR}lib/config.xml,out=${RESULTSDIR}spassmeter.txt,tcp=localhost:6002"

SERVER="-server -d64 -Xms1G -Xmx4G -classpath ${BASEDIR}lib/linux/spass-meter-ant.jar de.uni_hildesheim.sse.monitoring.runtime.recordingServer.TCPRecordingServer baseDir=. port=6002"

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
    echo "## Starting iteration ${i}/${NUM_LOOPS}" >>${BASEDIR}spassmeter.log

    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
    echo " # ${i}.${j}.${k} No instrumentation" >>${BASEDIR}spassmeter.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}spassmeter.log
    echo >>${BASEDIR}spassmeter.log
    sync
    sleep ${SLEEPTIME}

    # SPASSmeter Javassist Instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Instrumentation"
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Instrumentation" >>${BASEDIR}spassmeter.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${SERVER} 1>>server.out 2>&1 &
    ${JAVABIN}java ${JAVAARGS_LTW},mainDefault=NONE -DSpassmeterNoWriter=true ${JAR} -f \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill -9 $!
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}spassmeter.log
    echo >>${BASEDIR}spassmeter.log
    sync
    sleep ${SLEEPTIME}

    # SPASSmeter Javassist Collecting
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Collecting"
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Collecting" >>${BASEDIR}spassmeter.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${SERVER} 1>>server.out 2>&1 &
    ${JAVABIN}java ${JAVAARGS_LTW} -DSpassmeterNoWriter=true ${JAR} -f \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill -9 $!
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}spassmeter.log
    echo >>${BASEDIR}spassmeter.log
    sync
    sleep ${SLEEPTIME}

    # SPASSmeter Javassist Writing
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Writing"
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Writing" >>${BASEDIR}spassmeter.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${SERVER} 1>>server.out 2>&1 &
    ${JAVABIN}java ${JAVAARGS_LTW} -DSpassmeterNoWriter=fals ${JAR} -f \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill -9 $!
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}spassmeter.log
    echo >>${BASEDIR}spassmeter.log
    sync
    sleep ${SLEEPTIME}


done
#zip -jqr ${RESULTSDIR}stat.zip ${RESULTSDIR}stat
#rm -rf ${RESULTSDIR}stat/
mv ${BASEDIR}spassmeter.log ${RESULTSDIR}spassmeter.log
[ -f ${RESULTSDIR}hotspot-1-${RECURSIONDEPTH}-1.log ] && grep "<task " ${RESULTSDIR}hotspot-*.log >${RESULTSDIR}log.log
[ -f ${BASEDIR}errorlog.txt ] && mv ${BASEDIR}errorlog.txt ${RESULTSDIR}

## Clean up raw results
#gzip -qr ${RESULTSDIR}results.zip ${RAWFN}*
#rm -f ${RAWFN}*
[ -f ${BASEDIR}nohup.out ] && cp ${BASEDIR}nohup.out ${RESULTSDIR}
[ -f ${BASEDIR}server.out ] && mv ${BASEDIR}server.out ${RESULTSDIR}
[ -f ${BASEDIR}nohup.out ] && > ${BASEDIR}nohup.out
