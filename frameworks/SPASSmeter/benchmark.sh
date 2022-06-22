#!/bin/bash
# This file is configured for linux instead of solaris!!!

JAVA_BIN=""

RSCRIPT_DIR=r
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
MORE_PARAMS="--application moobench.application.MonitoredClassSimple ${MORE_PARAMS}"

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
JAVA_ARGS="${JAVA_ARGS} "
JAVA_ARGS="${JAVA_ARGS} -Xms1G -Xmx4G"
JAVA_ARGS="${JAVA_ARGS} -verbose:gc -XX:+PrintCompilation"
#JAVA_ARGS="${JAVA_ARGS} -XX:+PrintInlining"
#JAVA_ARGS="${JAVA_ARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVA_ARGS="${JAVA_ARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar"

JAVA_ARGS_NOINSTR="${JAVA_ARGS}"
JAVA_ARGS_LTW="${JAVA_ARGS} -javaagent:${BASE_DIR}/lib/linux/spass-meter-ia.jar=xmlconfig=${BASE_DIR}/lib/config.xml,out=${RESULTS_DIR}/spassmeter.txt"
JAVAARGS_LTW_ASM="${JAVAARGS_LTW} -Dspass-meter.iFactory=de.uni_hildesheim.sse.monitoring.runtime.instrumentation.asmTree.Factory"


## Write configuration
uname -a > "${RESULTS_DIR}/configuration.txt"
${JAVA_BIN} ${JAVA_ARGS} -version 2>> "${RESULTS_DIR}/configuration.txt"
echo "JAVA_ARGS: ${JAVA_ARGS}" >> "${RESULTS_DIR}/configuration.txt"
echo "" >> "${RESULTS_DIR}/configuration.txt"
echo "Runtime: circa ${TIME} seconds" >> "${RESULTS_DIR}/configuration.txt"
echo "" >> "${RESULTS_DIR}/configuration.txt"
echo "SLEEPTIME=${SLEEP_TIME}" >> "${RESULTS_DIR}/configuration.txt"
echo "NUM_LOOPS=${NUM_LOOPS}" >> "${RESULTS_DIR}/configuration.txt"
echo "TOTALCALLS=${TOTAL_CALLS}" >> "${RESULTS_DIR}/configuration.txt"
echo "METHODTIME=${METHOD_TIME}" >> "${RESULTS_DIR}/configuration.txt"
echo "THREADS=${THREADS}" >> "${RESULTS_DIR}/configuration.txt"
echo "RECURSIONDEPTH=${RECURSION_DEPTH}" >> "${RESULTS_DIR}/configuration.txt"
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
        --total-calls ${TOTAL_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MORE_PARAMS}
    #kill %sar
    [ -f "${BASE_DIR}/hotspot.log" ] && mv "${BASE_DIR}/hotspot.log" "${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    sync
    sleep "${SLEEP_TIME}"

    # SPASSmeter Javassist
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter Javassist"
    echo " # ${i}.${j}.${k} SPASSmeter Javassist" >> "${BASE_DIR}/spassmeter.log"
    #sar -o ${RESULTS_DIR}/stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVA_BIN} ${JAVAARGS_LTW} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTAL_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MORE_PARAMS}
    #kill %sar
    [ -f "${BASE_DIR}/hotspot.log" ] && mv "${BASE_DIR}/hotspot.log" "${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    sync
    sleep "${SLEEP_TIME}"
    
    # SPASSmeter ASM
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter ASM"
    echo " # ${i}.${j}.${k} SPASSmeter ASM" >> "${BASE_DIR}/spassmeter.log"
    #sar -o ${RESULTS_DIR}/stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVA_BIN} ${JAVAARGS_LTW_ASM} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTALCALLS} \
        --method-time ${METHODTIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MORE_PARAMS}
    #kill %sar
    [ -f ${BASE_DIR}/hotspot.log ] && mv ${BASE_DIR}/hotspot.log ${RESULTS_DIR}/hotspot-${i}-${j}-${k}.log
    echo >> "${BASE_DIR}/spassmeter.log"
    echo >> "${BASE_DIR}/spassmeter.log"
    sync
    sleep ${SLEEPTIME}

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
[ -f ${BASE_DIR}/nohup.out ] && > ${BASE_DIR}/nohup.out
