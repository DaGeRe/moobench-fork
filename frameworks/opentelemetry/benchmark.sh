#!/bin/bash
# This file is configured for linux instead of solaris!!!

function startZipkin {
	if [ ! -d zipkin ]
	then
		mkdir zipkin
		cd zipkin
		curl -sSL https://zipkin.io/quickstart.sh | bash -s
	fi
	cd zipkin
	java -Xmx6g -jar zipkin.jar &> zipkin.txt &
	sleep 5
	cd ..
}

function stopZipkin {
	kill %1
}

JAVABIN=""

RSCRIPTDIR=r/
BASEDIR=./
RESULTSDIR="${BASEDIR}tmp/results-opentelemetry/"

SLEEPTIME=30           ## 30
NUM_LOOPS=10           ## 10
THREADS=1              ## 1
RECURSIONDEPTH=10      ## 10
TOTALCALLS=2000000     ## 2000000
METHODTIME=0      ## 500000

#MOREPARAMS="--quickstart"
MOREPARAMS="--application moobench.application.MonitoredClassSimple ${MOREPARAMS}"

TIME=`expr ${METHODTIME} \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} + ${SLEEPTIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSIONDEPTH} + 50 \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '$RESULTSDIR'"
(rm -rf ${RESULTSDIR}) && mkdir -p ${RESULTSDIR}
#mkdir ${RESULTSDIR}stat/

# Clear opentelemetry.log and initialize logging
rm -f ${BASEDIR}opentelemetry.log
touch ${BASEDIR}opentelemetry.log

RAWFN="${RESULTSDIR}raw"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} "
JAVAARGS="${JAVAARGS} -Xms1G -Xmx4G"
JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASEDIR}lib/opentelemetry-javaagent-all.jar"
JAVAARGS_LTW_ASM="${JAVAARGS_LTW} -Dspass-meter.iFactory=de.uni_hildesheim.sse.monitoring.runtime.instrumentation.asmTree.Factory"


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
    echo "## Starting iteration ${i}/${NUM_LOOPS}" >>${BASEDIR}opentelemetry.log

    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
    echo " # ${i}.${j}.${k} No instrumentation" >>${BASEDIR}opentelemetry.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTALCALLS} \
        --method-time ${METHODTIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_pure.txt
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}opentelemetry.log
    echo >>${BASEDIR}opentelemetry.log
    sync
    sleep ${SLEEPTIME}

    # OpenTelemetry Instrumentation
    k=`expr ${k} + 1`
    startZipkin
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation"
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation" >>${BASEDIR}opentelemetry.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${JAVAARGS_LTW} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTALCALLS} \
        --method-time ${METHODTIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_opentelemetry.txt
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}opentelemetry.log
    echo >>${BASEDIR}opentelemetry.log
    stopZipkin
    sync
    sleep ${SLEEPTIME}

done
#zip -jqr ${RESULTSDIR}stat.zip ${RESULTSDIR}stat
#rm -rf ${RESULTSDIR}stat/
mv ${BASEDIR}opentelemetry.log ${RESULTSDIR}opentelemetry.log
[ -f ${RESULTSDIR}hotspot-1-${RECURSIONDEPTH}-1.log ] && grep "<task " ${RESULTSDIR}hotspot-*.log >${RESULTSDIR}log.log
[ -f ${BASEDIR}errorlog.txt ] && mv ${BASEDIR}errorlog.txt ${RESULTSDIR}

## Clean up raw results
#gzip -qr ${RESULTSDIR}results.zip ${RAWFN}*
#rm -f ${RAWFN}*
[ -f ${BASEDIR}nohup.out ] && cp ${BASEDIR}nohup.out ${RESULTSDIR}
[ -f ${BASEDIR}nohup.out ] && > ${BASEDIR}nohup.out
