#!/bin/bash
# This file is configured for linux instead of solaris!!!

JAVA_BIN=""

R_SCRIPT_DIR=r
BASE_DIR=.
RESULTS_DIR="${BASE_DIR}/tmp/results-spassmeter"

## TODO this should be moved to a config file
SLEEP_TIME=30           ## 30
NUM_LOOPS=10           ## 10
THREADS=1              ## 1
RECURSION_DEPTH=10      ## 10
TOTAL_CALLS=2000000     ## 2000000
METHOD_TIME=0      ## 500000

#MORE_PARAMS="--quickstart"
MORE_PARAMS="--application mooBench.monitoredApplication.MonitoredClassSimple ${MORE_PARAMS}"

TIME=`expr ${METHOD_TIME} \* ${TOTAL_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTAL_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '${RESULTS_DIR}'"
(rm -rf "${RESULTS_DIR}") && mkdir -p "${RESULTS_DIR}"
#mkdir ${RESULTS_DIR}/stat

# Clear spassmeter.log and initialize logging
rm -f "${BASE_DIR}/spassmeter.log"
touch "${BASE_DIR}/spassmeter.log"

RAWFN="${RESULTS_DIR}/raw"

JAVA_ARGS="-server"
JAVA_ARGS="${JAVA_ARGS} -d64"
JAVA_ARGS="${JAVA_ARGS} -Xms1G -Xmx12G"
JAVA_ARGS="${JAVA_ARGS} -verbose:gc -XX:+PrintCompilation"
#JAVA_ARGS="${JAVA_ARGS} -XX:+PrintInlining"
#JAVA_ARGS="${JAVA_ARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVA_ARGS="${JAVA_ARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar"

JAVA_ARGS_NOINSTR="${JAVA_ARGS}"
JAVA_ARGS_LTW="${JAVA_ARGS} -javaagent:${BASE_DIR}/lib/linux/spass-meter-ia.jar=xmlconfig=${BASE_DIR}/lib/config.xml,out=${RESULTS_DIR}/spassmeter.txt,tcp=localhost:6002"

SERVER="-server -d64 -Xms1G -Xmx4G -classpath ${BASE_DIR}/lib/linux/spass-meter-ant.jar de.uni_hildesheim.sse.monitoring.runtime.recordingServer.TCPRecordingServer baseDir=. port=6002"

## Write configuration
uname -a > "${RESULTS_DIR}/configuration.txt"
${JAVA_BIN} ${JAVA_ARGS} -version 2>> "${RESULTS_DIR}/configuration.txt"
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
    j="${RECURSION_DEPTH}"
    k=0
    echo "## Starting iteration ${i}/${NUM_LOOPS}"
    echo "## Starting iteration ${i}/${NUM_LOOPS}" >> "${BASE_DIR}/spassmeter.log"

    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
    echo " # ${i}.${j}.${k} No instrumentation" >> "${BASE_DIR}/spassmeter.log"
    #sar -o ${RESULTS_DIR}/stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVA_BIN} ${JAVA_ARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHOD_TIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MORE_PARAMS}
    #kill %sar
    [ -f "${BASE_DIR}/hotspot.log" ] && mv "${BASE_DIR}/hotspot.log" "${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    sync
    sleep "${SLEEP_TIME}"

    # SPASSmeter Javassist Instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Instrumentation"
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Instrumentation" >> "${BASE_DIR}/spassmeter.log"
    #sar -o ${RESULTS_DIR}/stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVA_BIN} ${SERVER} 1>>server.out 2>&1 &
    ${JAVA_BIN} ${JAVA_ARGS_LTW},mainDefault=NONE -DSpassmeterNoWriter=true ${JAR} -f \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHOD_TIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MORE_PARAMS}
    kill -9 $!
    #kill %sar
    [ -f "${BASE_DIR}/hotspot.log" ] && mv "${BASE_DIR}/hotspot.log" "${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    sync
    sleep "${SLEEP_TIME}"

    # SPASSmeter Javassist Collecting
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Collecting"
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Collecting" >> "${BASE_DIR}/spassmeter.log"
    #sar -o ${RESULTS_DIR}/stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVA_BIN} ${SERVER} 1>>server.out 2>&1 &
    ${JAVA_BIN} ${JAVA_ARGS_LTW} -DSpassmeterNoWriter=true ${JAR} -f \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHOD_TIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MORE_PARAMS}
    kill -9 $!
    #kill %sar
    [ -f "${BASE_DIR}/hotspot.log" ] && mv "${BASE_DIR}/hotspot.log" "${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    sync
    sleep "${SLEEP_TIME}"

    # SPASSmeter Javassist Writing
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Writing"
    echo " # ${i}.${j}.${k} SPASSmeter Javassist Writing" >> "${BASE_DIR}/spassmeter.log"
    #sar -o ${RESULTS_DIR}/stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVA_BIN} ${SERVER} 1>>server.out 2>&1 &
    ${JAVA_BIN} ${JAVA_ARGS_LTW} -DSpassmeterNoWriter=fals ${JAR} -f \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTAL_CALLS} \
        --methodtime ${METHOD_TIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MORE_PARAMS}
    kill -9 $!
    #kill %sar
    [ -f "${BASE_DIR}/hotspot.log" ] && mv "${BASE_DIR}/hotspot.log" "${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    sync
    sleep "${SLEEP_TIME}"


done
#zip -jqr ${RESULTS_DIR}/stat.zip ${RESULTS_DIR}/stat
#rm -rf ${RESULTS_DIR}/stat/
mv "${BASE_DIR}/spassmeter.log" "${RESULTS_DIR}/spassmeter.log"
[ -f "${RESULTS_DIR}/hotspot-1-${RECURSION_DEPTH}-1.log" ] && grep "<task " ${RESULTS_DIR}/hotspot-*.log > "${RESULTS_DIR}/log.log"
[ -f "${BASE_DIR}/errorlog.txt" ] && mv "${BASE_DIR}/errorlog.txt" "${RESULTS_DIR}/"

## Clean up raw results
#gzip -qr "${RESULTS_DIR}/results.zip" ${RAWFN}*
#rm -f ${RAWFN}*
[ -f "${BASE_DIR}/nohup.out" ] && cp "${BASE_DIR}/nohup.out" "${RESULTS_DIR}/"
[ -f "${BASE_DIR}/server.out" ] && mv "${BASE_DIR}/server.out" "${RESULTS_DIR}/"
[ -f "${BASE_DIR}/nohup.out" ] && > "${BASE_DIR}/nohup.out"

# end
