#!/bin/bash

BIN_DIR=bin/
BASEDIR=

# determine correct classpath separator
CPSEPCHAR=":" # default :, ; for windows
if [ ! -z "$(uname | grep -i WIN)" ]; then CPSEPCHAR=";"; fi
# echo "Classpath separator: '${CPSEPCHAR}'"

RESULTS_DIR="${BASEDIR}tmp/results-benchmark-recursive/"
echo "Removing and recreating '$RESULTS_DIR'"
(${SUDOCMD} rm -rf ${RESULTS_DIR}) && mkdir ${RESULTS_DIR}
mkdir ${RESULTS_DIR}stat/

# Clear kieker.log and initialize logging
rm -f ${BASEDIR}kieker.log
touch ${BASEDIR}kieker.log

RESULTSFN="${RESULTS_DIR}results.csv"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -d64"
JAVAARGS="${JAVAARGS} -Xms1G -Xmx1G"
JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASEDIR}lib/kieker-1.9-SNAPSHOT_aspectj.jar -Dorg.aspectj.weaver.showWeaveInfo=false -Daj.weaving.verbose=false"
JAVAARGS_KIEKER_DEACTV="${JAVAARGS_LTW} -Dkieker.monitoring.adaptiveMonitoring.configFile=META-INF/kieker.monitoring.adaptiveMonitoring.disabled.conf -Dkieker.monitoring.writer=kieker.monitoring.writer.DummyWriter"
JAVAARGS_KIEKER_NOLOGGING="${JAVAARGS_LTW} -Dkieker.monitoring.writer=kieker.monitoring.writer.DummyWriter"
JAVAARGS_KIEKER_LOGGING="${JAVAARGS_LTW} -Dkieker.monitoring.writer=kieker.monitoring.writer.filesystem.AsyncFsWriter -Dkieker.monitoring.writer.filesystem.AsyncFsWriter.customStoragePath=${BASEDIR}tmp"

## Write configuration
uname -a >${RESULTS_DIR}configuration.txt
java ${JAVAARGS} -version 2>>${RESULTS_DIR}configuration.txt
echo "JAVAARGS: ${JAVAARGS}" >>${RESULTS_DIR}configuration.txt
echo "" >>${RESULTS_DIR}configuration.txt
echo "Runtime: circa ${TIME} seconds" >>${RESULTS_DIR}configuration.txt
echo "" >>${RESULTS_DIR}configuration.txt
echo "SLEEPTIME=${SLEEPTIME}" >>${RESULTS_DIR}configuration.txt
echo "NUM_LOOPS=${NUM_LOOPS}" >>${RESULTS_DIR}configuration.txt
echo "TOTALCALLS=${TOTALCALLS}" >>${RESULTS_DIR}configuration.txt
echo "METHODTIME=${METHODTIME}" >>${RESULTS_DIR}configuration.txt
echo "THREADS=${THREADS}" >>${RESULTS_DIR}configuration.txt
echo "MAXRECURSIONDEPTH=${MAXRECURSIONDEPTH}" >>${RESULTS_DIR}configuration.txt
sync

## Execute Benchmark

for ((i=1;i<=${NUM_LOOPS};i+=1)); do
    echo "## Starting iteration ${i}/${NUM_LOOPS}"

    for ((j=1;j<=${MAXRECURSIONDEPTH};j+=1)); do
        echo "# Starting recursion ${i}.${j}/${MAXRECURSIONDEPTH}"

        # 1 No instrumentation
        echo " # ${i}.1 No instrumentation"
        mpstat 1 > ${RESULTS_DIR}stat/mpstat-${i}-${j}-1.txt &
        vmstat 1 > ${RESULTS_DIR}stat/vmstat-${i}-${j}-1.txt &
        iostat -xn 10 > ${RESULTS_DIR}stat/iostat-${i}-${j}-1.txt &
        ${BINDJAVA} java  ${JAVAARGS_NOINSTR} ${JAR} \
            --output-filename ${RESULTSFN}-${i}-${j}-1.csv \
            --totalcalls ${TOTALCALLS} \
            --methodtime ${METHODTIME} \
            --totalthreads ${THREADS} \
            --recursiondepth ${j}
        kill %mpstat
        kill %vmstat
        kill %iostat
        [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-1.log
        sync
        sleep ${SLEEPTIME}

        # 2 Deactivated probe
        echo " # ${i}.2 Deactivated probe"
        mpstat 1 > ${RESULTS_DIR}stat/mpstat-${i}-${j}-2.txt &
        vmstat 1 > ${RESULTS_DIR}stat/vmstat-${i}-${j}-2.txt &
        iostat -xn 10 > ${RESULTS_DIR}stat/iostat-${i}-${j}-2.txt &
        ${BINDJAVA} java  ${JAVAARGS_KIEKER_DEACTV} ${JAR} \
            --output-filename ${RESULTSFN}-${i}-${j}-2.csv \
            --totalcalls ${TOTALCALLS} \
            --methodtime ${METHODTIME} \
            --totalthreads ${THREADS} \
            --recursiondepth ${j}
        kill %mpstat
        kill %vmstat
        kill %iostat
        [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-2.log
        echo >>${BASEDIR}kieker.log
        echo >>${BASEDIR}kieker.log
        sync
        sleep ${SLEEPTIME}

        # 3 No logging
        echo " # ${i}.3 No logging (null writer)"
        mpstat 1 > ${RESULTS_DIR}stat/mpstat-${i}-${j}-3.txt &
        vmstat 1 > ${RESULTS_DIR}stat/vmstat-${i}-${j}-3.txt &
        iostat -xn 10 > ${RESULTS_DIR}stat/iostat-${i}-${j}-3.txt &
        ${BINDJAVA} java  ${JAVAARGS_KIEKER_NOLOGGING} ${JAR} \
            --output-filename ${RESULTSFN}-${i}-${j}-3.csv \
            --totalcalls ${TOTALCALLS} \
            --methodtime ${METHODTIME} \
            --totalthreads ${THREADS} \
            --recursiondepth ${j}
        kill %mpstat
        kill %vmstat
        kill %iostat
        [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-3.log
        echo >>${BASEDIR}kieker.log
        echo >>${BASEDIR}kieker.log
        sync
        sleep ${SLEEPTIME}

        # 4 Logging
        echo " # ${i}.4 Logging"
        mpstat 1 > ${RESULTS_DIR}stat/mpstat-${i}-${j}-4.txt &
        vmstat 1 > ${RESULTS_DIR}stat/vmstat-${i}-${j}-4.txt &
        iostat -xn 10 > ${RESULTS_DIR}stat/iostat-${i}-${j}-4.txt &
        ${BINDJAVA} java  ${JAVAARGS_KIEKER_LOGGING} ${JAR} \
            --output-filename ${RESULTSFN}-${i}-${j}-4.csv \
            --totalcalls ${TOTALCALLS} \
            --methodtime ${METHODTIME} \
            --totalthreads ${THREADS} \
            --recursiondepth ${j}
        kill %mpstat
        kill %vmstat
        kill %iostat
        mkdir -p ${RESULTS_DIR}kiekerlog/
        mv ${BASEDIR}tmp/kieker-* ${RESULTS_DIR}kiekerlog/
        [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-4.log
        echo >>${BASEDIR}kieker.log
        echo >>${BASEDIR}kieker.log
        sync
        sleep ${SLEEPTIME}
    
    done

done
tar cf ${RESULTS_DIR}kiekerlog.tar ${RESULTS_DIR}kiekerlog
${SUDOCMD} rm -rf ${RESULTS_DIR}kiekerlog/
gzip -9 ${RESULTS_DIR}kiekerlog.tar
tar cf ${RESULTS_DIR}stat.tar ${RESULTS_DIR}stat
rm -rf ${RESULTS_DIR}stat/
gzip -9 ${RESULTS_DIR}stat.tar
mv ${BASEDIR}kieker.log ${RESULTS_DIR}kieker.log
[ -f ${RESULTS_DIR}hotspot-1-1-1.log ] && grep "<task " ${RESULTS_DIR}hotspot-*.log >${RESULTS_DIR}log.log
[ -f ${BASEDIR}nohup.out ] && cp ${BASEDIR}nohup.out ${RESULTS_DIR}
echo -n "" > ${BASEDIR}nohup.out
[ -f ${BASEDIR}errorlog.txt ] && mv ${BASEDIR}errorlog.txt ${RESULTS_DIR}
echo -n "" > ${BASEDIR}errorlog.txt
