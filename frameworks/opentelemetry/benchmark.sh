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
	./prometheus &> prometheus.log &
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
	./jaeger-all-in-one &> jaeger.log &
	cd ..
}

function stopBackgroundProcess {
	kill %1
}

function cleanup {
	[ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTS_DIR}hotspot-${i}-${j}-${k}.log
	echo >>${BASEDIR}opentelemetry.log
	echo >>${BASEDIR}opentelemetry.log
	sync
	sleep ${SLEEP_TIME}
}

function runNoInstrumentation {
    # No instrumentation
    echo " # ${i}.${j}.${k} No instrumentation"
    echo " # ${i}.${j}.${k} No instrumentation" >>${BASEDIR}opentelemetry.log
    ${JAVABIN}java ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MOREPARAMS} &> ${RESULTS_DIR}output_"$i"_uninstrumented.txt
}

function runOpenTelemetryNoLogging {
    # OpenTelemetry Instrumentation Logging Deactivated
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Logging Deactivated"
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Logging Deactivated" >>${BASEDIR}opentelemetry.log
    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_LOGGING_DEACTIVATED} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MOREPARAMS} &> ${RESULTS_DIR}output_"$i"_opentelemetry.txt
}

function runOpenTelemetryLogging {
    # OpenTelemetry Instrumentation Logging
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Logging"
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Logging" >>${BASEDIR}opentelemetry.log
    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_LOGGING} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MOREPARAMS} &> ${RESULTS_DIR}output_"$i"_opentelemetry_logging.txt
    if [ ! "$DEBUG" = true ]
    then
    	echo "DEBUG is $DEBUG, deleting opentelemetry logging file"
    	rm ${RESULTS_DIR}output_"$i"_opentelemetry_logging.txt
    fi
}

function runOpenTelemetryZipkin {
    # OpenTelemetry Instrumentation Zipkin
    k=`expr ${k} + 1`
    startZipkin
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Zipkin"
    echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Zipkin" >>${BASEDIR}opentelemetry.log
    ${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_ZIPKIN} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${j} \
        ${MOREPARAMS} &> ${RESULTS_DIR}output_"$i"_opentelemetry_zipkin.txt
    stopBackgroundProcess
}

function runOpenTelemetryJaeger {
	# OpenTelemetry Instrumentation Jaeger
	k=`expr ${k} + 1`
	startJaeger
	echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Jaeger"
	echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Jaeger" >>${BASEDIR}opentelemetry.log
	${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_JAEGER} ${JAR} \
		--output-filename ${RAWFN}-${i}-${j}-${k}.csv \
		--total-calls ${TOTAL_NUM_OF_CALLS} \
		--method-time ${METHODTIME} \
		--total-threads ${THREADS} \
		--recursion-depth ${j} \
		${MOREPARAMS} &> ${RESULTS_DIR}output_"$i"_opentelemetry_jaeger.txt
	stopBackgroundProcess
}

function runOpenTelemetryPrometheus {
	# OpenTelemetry Instrumentation Prometheus
	k=`expr ${k} + 1`
	startPrometheus
	echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Prometheus"
	echo " # ${i}.${j}.${k} OpenTelemetry Instrumentation Prometheus" >>${BASEDIR}opentelemetry.log
	${JAVABIN}java ${JAVAARGS_OPENTELEMETRY_PROMETHEUS} ${JAR} \
		--output-filename ${RAWFN}-${i}-${j}-${k}.csv \
		--total-calls ${TOTAL_NUM_OF_CALLS} \
		--method-time ${METHOD_TIME} \
		--total-threads ${THREADS} \
		--recursion-depth ${j} \
		${MOREPARAMS} &> ${RESULTS_DIR}output_"$i"_opentelemetry_prometheus.txt
	stopBackgroundProcess
}

function printIntermediaryResults {
    echo -n "Intermediary results uninstrumented "
    cat results-opentelemetry/raw-*-$RECURSION_DEPTH-0.csv | awk -F';' '{print $2}' | getSum
    
    echo -n "Intermediary results opentelemetry Logging Deactivated "
    cat results-opentelemetry/raw-*-$RECURSION_DEPTH-1.csv | awk -F';' '{print $2}' | getSum
    
    echo -n "Intermediary results opentelemetry Logging "
    cat results-opentelemetry/raw-*-$RECURSION_DEPTH-2.csv | awk -F';' '{print $2}' | getSum
    
    echo -n "Intermediary results opentelemetry Zipkin "
    cat results-opentelemetry/raw-*-$RECURSION_DEPTH-3.csv | awk -F';' '{print $2}' | getSum
    
    MACHINE_TYPE=`uname -m`; 
    if [ ${MACHINE_TYPE} == 'x86_64' ]
    then
        echo -n "Intermediary results opentelemetry Jaeger "
    	cat results-opentelemetry/raw-*-$RECURSION_DEPTH-4.csv | awk -F';' '{print $2}' | getSum
    
    	# Prometheus does not work currently
	#echo -n "Intermediary results opentelemetry Prometheus"
    	#cat results-opentelemetry/raw-*-$RECURSION_DEPTH-5.csv | awk -F';' '{print $2}' | getSum
    fi
}


JAVABIN=""

RSCRIPTDIR=r/
BASEDIR=./
RESULTS_DIR="${BASEDIR}results-opentelemetry/"

source ../common-functions.sh
echo "NUM_OF_LOOPS: $NUM_OF_LOOPS"

#MOREPARAMS="--quickstart"
MOREPARAMS="--application moobench.application.MonitoredClassSimple ${MOREPARAMS}"

TIME=`expr ${METHOD_TIME} \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_OF_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Cleaning and recreating '$RESULTS_DIR'"
(rm -rf ${RESULTS_DIR}/**csv) && mkdir -p ${RESULTS_DIR}
#mkdir ${RESULTS_DIR}stat/

# Clear opentelemetry.log and initialize logging
rm -f ${BASEDIR}opentelemetry.log
touch ${BASEDIR}opentelemetry.log

RAWFN="${RESULTS_DIR}raw"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} "
JAVAARGS="${JAVAARGS} -Xms1G -Xmx2G"
JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar"

if [ ! -f "MooBench.jar" ]
then
	echo "MooBench.jar missing; please build it first using ../gradlew assemble in the benchmark folder"
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
uname -a >${RESULTS_DIR}configuration.txt
${JAVABIN}java ${JAVAARGS} -version 2>>${RESULTS_DIR}configuration.txt
echo "JAVAARGS: ${JAVAARGS}" >>${RESULTS_DIR}configuration.txt
echo "" >>${RESULTS_DIR}configuration.txt
echo "Runtime: circa ${TIME} seconds" >>${RESULTS_DIR}configuration.txt
echo "" >>${RESULTS_DIR}configuration.txt
echo "SLEEPTIME=${SLEEPTIME}" >>${RESULTS_DIR}configuration.txt
echo "NUM_OF_LOOPS=${NUM_OF_LOOPS}" >>${RESULTS_DIR}configuration.txt
echo "TOTAL_NUM_OF_CALLS=${TOTAL_NUM_OF_CALLS}" >>${RESULTS_DIR}configuration.txt
echo "METHODTIME=${METHODTIME}" >>${RESULTS_DIR}configuration.txt
echo "THREADS=${THREADS}" >>${RESULTS_DIR}configuration.txt
echo "RECURSION_DEPTH=${RECURSION_DEPTH}" >>${RESULTS_DIR}configuration.txt
sync

## Execute Benchmark
for ((i=1;i<=${NUM_OF_LOOPS};i+=1)); do
    j=${RECURSION_DEPTH}
    k=0
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}"
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}" >>${BASEDIR}opentelemetry.log

    runNoInstrumentation
    cleanup

    runOpenTelemetryNoLogging
    cleanup

    runOpenTelemetryLogging
    cleanup
    
    runOpenTelemetryZipkin
    cleanup
    
    MACHINE_TYPE=`uname -m`; 
    if [ ${MACHINE_TYPE} == 'x86_64' ]
    then
    	    runOpenTelemetryJaeger
	    cleanup
	    
	    # Prometheus does not work currently
	    #runOpenTelemetryPrometheus
	    #cleanup
    else
    	echo "No 64 Bit System; skipping Prometheus"
    fi

    printIntermediaryResults
done

cleanup-results

#zip -jqr ${RESULTS_DIR}stat.zip ${RESULTS_DIR}stat
#rm -rf ${RESULTS_DIR}stat/
mv ${BASEDIR}opentelemetry.log ${RESULTS_DIR}opentelemetry.log
[ -f ${RESULTS_DIR}hotspot-1-${RECURSION_DEPTH}-1.log ] && grep "<task " ${RESULTS_DIR}hotspot-*.log >${RESULTS_DIR}log.log
[ -f ${BASEDIR}errorlog.txt ] && mv ${BASEDIR}errorlog.txt ${RESULTS_DIR}

## Clean up raw results
#gzip -qr ${RESULTS_DIR}results.zip ${RAWFN}*
#rm -f ${RAWFN}*
[ -f ${BASEDIR}nohup.out ] && cp ${BASEDIR}nohup.out ${RESULTS_DIR}
[ -f ${BASEDIR}nohup.out ] && > ${BASEDIR}nohup.out
