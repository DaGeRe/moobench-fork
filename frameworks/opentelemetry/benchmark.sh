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

function startPrometheus {
	if [ ! -d prometheus-2.28.1.linux-amd64 ]
	then
		wget https://github.com/prometheus/prometheus/releases/download/v2.28.1/prometheus-2.28.1.linux-amd64.tar.gz
		tar -xvf prometheus-2.28.1.linux-amd64.tar.gz
		rm prometheus-2.28.1.linux-amd64.tar.gz
	fi
	cd prometheus-2.28.1.linux-amd64
	./prometheus > prometheus.log &
	cd ..
}


function startJaeger {
	if [ ! -d jaeger-1.24.0-linux-amd64 ]
	then
		wget https://github.com/jaegertracing/jaeger/releases/download/v1.24.0/jaeger-1.24.0-linux-amd64.tar.gz
		tar -xvf jaeger-1.24.0-linux-amd64.tar.gz
		rm jaeger-1.24.0-linux-amd64.tar.gz
	fi
	cd jaeger-1.24.0-linux-amd64
	./jaeger-all-in-one > jaeger.log &
	cd ..
}

function stopBackgroundProcess {
	kill %1
}


function getSum {
  awk '{sum += $1; square += $1^2} END {print "Average: "sum/NR" Standard Deviation: "sqrt(square / NR - (sum/NR)^2)" Count: "NR}'
}

function printIntermediaryResults {
    echo -n "Intermediary results uninstrumented"
    cat tmp/results-opentelemetry/raw-*-$RECURSIONDEPTH-1.csv | awk -F';' '{print $2}' | getSum
    
    echo -n "Intermediary results opentelemetry Logging Deactivated"
    cat tmp/results-opentelemetry/raw-*-$RECURSIONDEPTH-2.csv | awk -F';' '{print $2}' | getSum
    
    echo -n "Intermediary results opentelemetry Logging"
    cat tmp/results-opentelemetry/raw-*-$RECURSIONDEPTH-3.csv | awk -F';' '{print $2}' | getSum
    
    echo -n "Intermediary results opentelemetry Zipkin"
    cat tmp/results-opentelemetry/raw-*-$RECURSIONDEPTH-4.csv | awk -F';' '{print $2}' | getSum
    
    MACHINE_TYPE=`uname -m`; 
    if [ ${MACHINE_TYPE} == 'x86_64' ]
    then
        echo -n "Intermediary results opentelemetry Jaeger"
    	cat tmp/results-opentelemetry/raw-*-$RECURSIONDEPTH-5.csv | awk -F';' '{print $2}' | getSum
    
    	echo -n "Intermediary results opentelemetry Prometheus"
    	cat tmp/results-opentelemetry/raw-*-$RECURSIONDEPTH-6.csv | awk -F';' '{print $2}' | getSum
    fi
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

if [ ! -f "MooBench.jar" ]
then
	echo "MooBench.jar missing; please build it first using ./gradlew assemble in the main folder"
	exit 1
fi

if [ ! -f ${BASEDIR}lib/opentelemetry-javaagent-all.jar ]
then
	mkdir -p ${BASEDIR}lib
	wget --output-document=${BASEDIR}lib/opentelemetry-javaagent-all.jar \
		https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent-all.jar
fi

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_OPENTELEMETRY_BASIC="${JAVAARGS} -javaagent:${BASEDIR}lib/opentelemetry-javaagent-all.jar -Dotel.resource.attributes=service.name=moobench -Dotel.instrumentation.methods.include=moobench.application.MonitoredClassSimple[monitoredMethod];moobench.application.MonitoredClassThreaded[monitoredMethod]"
JAVAARGS_OPENTELEMETRY_LOGGING_DEACTIVATED="${JAVAARGS_OPENTELEMETRY_BASIC} -Dotel.traces.exporter=logging -Dotel.traces.sampler=always_off"
JAVAARGS_OPENTELEMETRY_LOGGING="${JAVAARGS_OPENTELEMETRY_BASIC} -Dotel.traces.exporter=logging"
JAVAARGS_OPENTELEMETRY_ZIPKIN="${JAVAARGS_OPENTELEMETRY_BASIC} -Dotel.traces.exporter=zipkin"
JAVAARGS_OPENTELEMETRY_JAEGER="${JAVAARGS_OPENTELEMETRY_BASIC} -Dotel.traces.exporter=jaeger"
JAVAARGS_OPENTELEMETRY_PROMETHEUS="${JAVAARGS_OPENTELEMETRY_BASIC} -Dotel.traces.exporter=prometheus"


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
        ${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_uninstrumented.txt
    #kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}opentelemetry.log
    echo >>${BASEDIR}opentelemetry.log
    sync
    sleep ${SLEEPTIME}

    # OpenTelemetry Instrumentation Logging Deactivated
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Logging Deactivated"
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Logging Deactivated" >>${BASEDIR}opentelemetry.log
    #sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_LOGGING_DEACTIVATED} ${JAR} \
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
    sync
    sleep ${SLEEPTIME}

    # OpenTelemetry Instrumentation Logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Logging"
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Logging" >>${BASEDIR}opentelemetry.log
    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_LOGGING} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTALCALLS} \
        --method-time ${METHODTIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_opentelemetry_logging.txt
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}opentelemetry.log
    echo >>${BASEDIR}opentelemetry.log
    sync
    sleep ${SLEEPTIME}
    
    # OpenTelemetry Instrumentation Zipkin
    k=`expr ${k} + 1`
    startZipkin
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Zipkin"
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Zipkin" >>${BASEDIR}opentelemetry.log
    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_ZIPKIN} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTALCALLS} \
        --method-time ${METHODTIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_opentelemetry_zipkin.txt
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}opentelemetry.log
    echo >>${BASEDIR}opentelemetry.log
    stopBackgroundProcess
    sync
    sleep ${SLEEPTIME}
    
    MACHINE_TYPE=`uname -m`; 
    if [ ${MACHINE_TYPE} == 'x86_64' ]
    then
    	    # OpenTelemetry Instrumentation Jaeger
	    k=`expr ${k} + 1`
	    startPrometheus
	    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Jaeger"
	    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Jaeger" >>${BASEDIR}opentelemetry.log
	    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_JAEGER} ${JAR} \
		--output-filename ${RAWFN}-${i}-${j}-${k}.csv \
		--total-calls ${TOTALCALLS} \
		--method-time ${METHODTIME} \
		--total-threads ${THREADS} \
		--recursion-depth ${j} \
		${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_opentelemetry_prometheus.txt
	    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
	    echo >>${BASEDIR}opentelemetry.log
	    echo >>${BASEDIR}opentelemetry.log
	    stopBackgroundProcess
	    sync
	    sleep ${SLEEPTIME}
	    
	    # OpenTelemetry Instrumentation Prometheus
	    k=`expr ${k} + 1`
	    startPrometheus
	    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Prometheus"
	    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Prometheus" >>${BASEDIR}opentelemetry.log
	    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_PROMETHEUS} ${JAR} \
		--output-filename ${RAWFN}-${i}-${j}-${k}.csv \
		--total-calls ${TOTALCALLS} \
		--method-time ${METHODTIME} \
		--total-threads ${THREADS} \
		--recursion-depth ${j} \
		${MOREPARAMS} &> ${RESULTSDIR}output_"$i"_opentelemetry_prometheus.txt
	    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
	    echo >>${BASEDIR}opentelemetry.log
	    echo >>${BASEDIR}opentelemetry.log
	    stopBackgroundProcess
	    sync
	    sleep ${SLEEPTIME}
    else
    	echo "No 64 Bit System; skipping Prometheus"
    fi

    printIntermediaryResults
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
