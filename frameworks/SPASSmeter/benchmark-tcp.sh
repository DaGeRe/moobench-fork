#!/bin/bash
# This file is configured for linux instead of solaris!!!

JAVABIN=""

RSCRIPTDIR=r/
BASEDIR=./
RESULTS_DIR="${BASE_DIR}/tmp/results-spassmeter/"

SLEEPTIME=30           ## 30
NUM_LOOPS=10           ## 10
THREADS=1              ## 1
RECURSIONDEPTH=10      ## 10
TOTAL_CALLS=2000000     ## 2000000
METHOD_TIME=0      ## 500000

#MORE_PARAMS="--quickstart"
MORE_PARAMS="--application mooBench.monitoredApplication.MonitoredClassSimple ${MORE_PARAMS}"

TIME=`expr ${METHOD_TIME} \* ${TOTAL_CALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSIONDEPTH} + 50 \* ${TOTAL_CALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '$RESULTS_DIR'"
(rm -rf ${RESULTS_DIR}/) && mkdir ${RESULTS_DIR}/
#mkdir ${RESULTS_DIR}/stat/

# Clear spassmeter.log and initialize logging
rm -f ${BASE_DIR}/spassmeter.log
touch ${BASE_DIR}/spassmeter.log

RAWFN="${RESULTS_DIR}/raw"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -d64"
JAVAARGS="${JAVAARGS} -Xms1G -Xmx4G"
JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASE_DIR}/lib/linux/spass-meter-ia.jar=xmlconfig=${BASE_DIR}/lib/config.xml,out=${RESULTS_DIR}/spassmeter.txt,tcp=localhost:6002"
JAVAARGS_LTW_ASM="${JAVAARGS_LTW} -Dspass-meter.iFactory=de.uni_hildesheim.sse.monitoring.runtime.instrumentation.asmTree.Factory"

SERVER="${JAVAARGS} -classpath ${BASE_DIR}/lib/linux/spass-meter-ant.jar de.uni_hildesheim.sse.monitoring.runtime.recordingServer.TCPRecordingServer baseDir=. port=6002"

## Write configuration
uname -a >${RESULTS_DIR}/configuration.txt
${JAVA_BIN} ${JAVAARGS} -version 2>>${RESULTS_DIR}/configuration.txt
echo "JAVAARGS: ${JAVAARGS}" >>${RESULTS_DIR}/configuration.txt
echo "" >>${RESULTS_DIR}/configuration.txt
echo "Runtime: circa ${TIME} seconds" >>${RESULTS_DIR}/configuration.txt
echo "" >>${RESULTS_DIR}/configuration.txt
echo "SLEEPTIME=${SLEEP_TIME}" >>${RESULTS_DIR}/configuration.txt
echo "NUM_LOOPS=${NUM_LOOPS}" >>${RESULTS_DIR}/configuration.txt
echo "TOTAL_CALLS=${TOTAL_CALLS}" >>${RESULTS_DIR}/configuration.txt
echo "METHOD_TIME=${METHOD_TIME}" >>${RESULTS_DIR}/configuration.txt
echo "THREADS=${THREADS}" >>${RESULTS_DIR}/configuration.txt
echo "RECURSIONDEPTH=${RECURSIONDEPTH}" >>${RESULTS_DIR}/configuration.txt
sync

## Execute Benchmark
for ((i=1;i<=${NUM_LOOPS};i+=1)); do
    j=${RECURSIONDEPTH}
    k=0
    echo "## Starting iteration ${i}/${NUM_LOOPS}"
    echo "## Starting iteration ${i}/${NUM_LOOPS}" >>${BASE_DIR}/spassmeter.log

    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
    echo " # ${i}.${j}.${k} No instrumentation" >>${BASE_DIR}/spassmeter.log
    #sar -o ${RESULTS_DIR}/stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVA_BIN} ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHOD_TIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MORE_PARAMS}
    #kill %sar
    [ -f ${BASE_DIR}/hotspot.log ] && mv ${BASE_DIR}/hotspot.log ${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log
    echo >>${BASE_DIR}/spassmeter.log
    echo >>${BASE_DIR}/spassmeter.log
    sync
    sleep ${SLEEP_TIME}

    # SPASSmeter Javassist
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter Javassist"
    echo " # ${i}.${j}.${k} SPASSmeter Javassist" >>${BASE_DIR}/spassmeter.log
    #sar -o ${RESULTS_DIR}/stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVA_BIN} ${SERVER} 1>>server.out 2>&1 &
    ${JAVA_BIN} ${JAVAARGS_LTW} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHOD_TIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MORE_PARAMS}
    #kill %sar
    [ -f ${BASE_DIR}/hotspot.log ] && mv ${BASE_DIR}/hotspot.log ${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log
    echo >>${BASE_DIR}/spassmeter.log
    echo >>${BASE_DIR}/spassmeter.log
    sync
    sleep ${SLEEP_TIME}
    
    # SPASSmeter ASM
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter ASM"
    echo " # ${i}.${j}.${k} SPASSmeter ASM" >>${BASE_DIR}/spassmeter.log
    #sar -o ${RESULTS_DIR}/stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVA_BIN} ${SERVER} 1>>server.out 2>&1 &
    ${JAVA_BIN} ${JAVAARGS_LTW_ASM} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHOD_TIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MORE_PARAMS}
    #kill %sar
    [ -f ${BASE_DIR}/hotspot.log ] && mv ${BASE_DIR}/hotspot.log ${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log
    echo >>${BASE_DIR}/spassmeter.log
    echo >>${BASE_DIR}/spassmeter.log
    sync
    sleep ${SLEEP_TIME}

done
#zip -jqr ${RESULTS_DIR}/stat.zip ${RESULTS_DIR}/stat
#rm -rf ${RESULTS_DIR}/stat/
mv ${BASE_DIR}/spassmeter.log ${RESULTS_DIR}/spassmeter.log
[ -f ${RESULTS_DIR}/hotspot-1-${RECURSIONDEPTH}-1.log ] && grep "<task " ${RESULTS_DIR}/hotspot-*.log >${RESULTS_DIR}/log.log
[ -f ${BASE_DIR}/errorlog.txt ] && mv ${BASE_DIR}/errorlog.txt ${RESULTS_DIR}/

## Clean up raw results
#gzip -qr ${RESULTS_DIR}/results.zip ${RAWFN}*
#rm -f ${RAWFN}*
[ -f ${BASE_DIR}/nohup.out ] && cp ${BASE_DIR}/nohup.out ${RESULTS_DIR}/
[ -f ${BASE_DIR}/server.out ] && mv ${BASE_DIR}/server.out ${RESULTS_DIR}/
[ -f ${BASE_DIR}/nohup.out ] && > ${BASE_DIR}/nohup.out
