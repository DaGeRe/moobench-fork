#!/bin/bash

function runNoInstrumentation {
    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
    echo " # ${i}.${j}.${k} No instrumentation" >>${BASEDIR}inspectit.log
    ${JAVABIN}java ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTALCALLS} \
        --method-time ${METHODTIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_"$j"_noinstrumentation.txt
}

function runInspectITZipkin {
    # InspectIT (minimal)
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} InspectIT (minimal)"
    echo " # ${i}.${j}.${k} InspectIT (minimal)" >>${BASEDIR}inspectit.log
    #${JAVABIN}java ${CMR_ARGS} -Xloggc:${BASEDIR}logs/gc.log -jar CMR/inspectit-cmr-mod.jar 1>>${BASEDIR}logs/out.log 2>&1 &
    startZipkin
    sleep 10
    echo $JAVAARGS_INSPECTIT_MINIMAL
    echo $JAR
    ${JAVABIN}java ${JAVAARGS_INSPECTIT_MINIMAL} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTALCALLS} \
        --method-time ${METHODTIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_"$j"_inspectit.txt
    sleep 10
    stopBackgroundProcess
}

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

function stopBackgroundProcess {
	kill %1
}

function cleanup {
	[ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
	echo >>${BASEDIR}inspectit.log
	echo >>${BASEDIR}inspectit.log
	sync
	sleep ${SLEEPTIME}
}

function getSum {
  awk '{sum += $1; square += $1^2} END {print "Average: "sum/NR" Standard Deviation: "sqrt(square / NR - (sum/NR)^2)" Count: "NR}'
}

function printIntermediaryResults {
    echo -n "Intermediary results uninstrumented "
    cat tmp/results-inspectit/raw-*-$RECURSIONDEPTH-1.csv | awk -F';' '{print $2}' | getSum
    
    echo -n "Intermediary results inspectIT "
    cat tmp/results-inspectit/raw-*-$RECURSIONDEPTH-2.csv | awk -F';' '{print $2}' | getSum
}

JAVABIN=""

RSCRIPTDIR=r/
BASEDIR=./
RESULTSDIR="${BASEDIR}tmp/results-inspectit/"

SLEEPTIME=30           ## 30
NUM_LOOPS=10           ## 10
THREADS=1              ## 1
RECURSIONDEPTH=10      ## 10
TOTALCALLS=2000000     ## 2000000
METHODTIME=0           ## 0

if [ ! -d agent ]
then
	mkdir agent
	cd agent
	wget https://github.com/inspectIT/inspectit-ocelot/releases/download/1.10.1/inspectit-ocelot-agent-1.10.1.jar
	cd ..
fi

#MOREPARAMS="--quickstart"
MOREPARAMS="${MOREPARAMS}"

TIME=`expr ${METHODTIME} \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} + ${SLEEPTIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSIONDEPTH} + 50 \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '$RESULTSDIR'"
(rm -rf ${RESULTSDIR}) && mkdir -p ${RESULTSDIR}
mkdir ${RESULTSDIR}stat/

# Clear inspectit.log and initialize logging
rm -f ${BASEDIR}inspectit.log
touch ${BASEDIR}inspectit.log
mkdir ${BASEDIR}logs/

RAWFN="${RESULTSDIR}raw"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -Xms1G -Xmx2G"
JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar --application moobench.application.MonitoredClassSimple"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASEDIR}agent/inspectit-ocelot-agent-1.10.1.jar -Djava.util.logging.config.file=${BASEDIR}config/logging.properties"
JAVAARGS_INSPECTIT_MINIMAL="${JAVAARGS_LTW} -Dinspectit.service-name='My-Custom-Service' -Dinspectit.exporters.tracing.zipkin.url=http://127.0.0.1:9411/api/v2/spans -Dinspectit.config.file-based.path=${BASEDIR}config/isequence/"
JAVAARGS_INSPECTIT_FULL="${JAVAARGS_LTW} -Dinspectit.config=${BASEDIR}config/timer/"

CMR_ARGS=" -Xms12G -Xmx12G -Xmn4G -XX:MaxPermSize=128m -XX:PermSize=128m -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=80 -XX:+UseCMSInitiatingOccupancyOnly -XX:+UseParNewGC -XX:+CMSParallelRemarkEnabled -XX:+DisableExplicitGC -XX:SurvivorRatio=4 -XX:TargetSurvivorRatio=90 -XX:+AggressiveOpts -XX:+UseFastAccessorMethods -XX:+UseBiasedLocking -XX:+HeapDumpOnOutOfMemoryError -server -verbose:gc -XX:+PrintGCTimeStamps -XX:+PrintGCDetails -XX:+PrintTenuringDistribution -Dinspectit.logging.config=config/logging-config.xml"

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

    runNoInstrumentation
    cleanup

    runInspectITZipkin
    cleanup
    
    printIntermediaryResults
done
zip -jqr ${RESULTSDIR}stat.zip ${RESULTSDIR}stat
rm -rf ${RESULTSDIR}stat/
mv ${BASEDIR}inspectit.log ${RESULTSDIR}inspectit.log
mv ${BASEDIR}logs/ ${RESULTSDIR}
[ -f ${RESULTSDIR}hotspot-1-${RECURSIONDEPTH}-1.log ] && grep "<task " ${RESULTSDIR}hotspot-*.log >${RESULTSDIR}log.log
[ -f ${BASEDIR}errorlog.txt ] && mv ${BASEDIR}errorlog.txt ${RESULTSDIR}

## Generate Results file
# Timeseries
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTSDIR}results-timeseries.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","InspectIT (minimal)","InspectIT (without CMR)","InspectIT (with CMR)")
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
configs.labels=c("No Probe","InspectIT (minimal)","InspectIT (without CMR)","InspectIT (with CMR)")
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
configs.labels=c("No Probe","InspectIT (minimal)","InspectIT (without CMR)","InspectIT (with CMR)")
results.count=${TOTALCALLS}
results.skip=${TOTALCALLS}*3/4
source("${RSCRIPTDIR}stats.r")
EOF

## Clean up raw results
zip -jqr ${RESULTSDIR}results.zip ${RAWFN}*
rm -f ${RAWFN}*
[ -f ${BASEDIR}nohup.out ] && cp ${BASEDIR}nohup.out ${RESULTSDIR}
[ -f ${BASEDIR}nohup.out ] && > ${BASEDIR}nohup.out
