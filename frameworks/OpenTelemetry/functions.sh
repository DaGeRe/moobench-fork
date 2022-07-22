# OpenTelementry specific functions

# ensure the script is sourced
if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "Hey, you should source this script, not execute it!"
    exit 1
fi


function getAgent() {
	if [ ! -f "${BASE_DIR}/lib/opentelemetry-javaagent.jar" ]
	then
		mkdir -p "${BASE_DIR}/lib"
		wget --output-document="${BASE_DIR}/lib/opentelemetry-javaagent.jar" \
			https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
	fi
}

function startJaeger {
	if [ ! -d "${BASE_DIR}/jaeger-1.24.0-linux-amd64" ] ; then
		cd "${BASE_DIR}"
		wget https://github.com/jaegertracing/jaeger/releases/download/v1.24.0/jaeger-1.24.0-linux-amd64.tar.gz
		tar -xvf jaeger-1.24.0-linux-amd64.tar.gz
		rm jaeger-1.24.0-linux-amd64.tar.gz
	fi
	
	cd "${BASE_DIR}/jaeger-1.24.0-linux-amd64"
	./jaeger-all-in-one &> jaeger.log &
	cd "${BASE_DIR}"
}

function cleanup {
	[ -f "${BASE_DIR}/hotspot.log" ] && mv "${BASE_DIR}/hotspot.log" "${RESULTS_DIR}/hotspot-${i}-$RECURSION_DEPTH-${k}.log"
	echo >> "${BASE_DIR}/OpenTelemetry.log"
	echo >> "${BASE_DIR}/OpenTelemetry.log"
	sync
	sleep "${SLEEP_TIME}"
}

function runNoInstrumentation {
    # No instrumentation
    info " # ${i}.$RECURSION_DEPTH.${k} ${TITLE[$k]}"
    echo " # ${i}.$RECURSION_DEPTH.${k} ${TITLE[$k]}" >> "${BASE_DIR}/OpenTelemetry.log"
    ${JAVA_BIN} ${JAVA_ARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth $RECURSION_DEPTH \
        ${MORE_PARAMS} &> "${RESULTS_DIR}/output_${i}_${RECURSION_DEPTH}_${k}.txt"
}

function runOpenTelemetryNoLogging {
    # OpenTelemetry Instrumentation Logging Deactivated
    k=`expr ${k} + 1`
    info " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}/OpenTelemetry.log
    ${JAVA_BIN} ${JAVA_ARGS_OPENTELEMETRY_LOGGING_DEACTIVATED} ${JAR} \
        --output-filename "${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv" \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth ${RECURSION_DEPTH} \
        ${MORE_PARAMS} &> "${RESULTS_DIR}/output_${i}_${RECURSION_DEPTH}_${k}.txt"
}

function runOpenTelemetryLogging {
    # OpenTelemetry Instrumentation Logging
    k=`expr ${k} + 1`
    info " # ${i}.$RECURSION_DEPTH.${k} ${TITLE[$k]}"
    echo " # ${i}.$RECURSION_DEPTH.${k} ${TITLE[$k]}" >> "${BASE_DIR}/OpenTelemetry.log"
    ${JAVA_BIN} ${JAVA_ARGS_OPENTELEMETRY_LOGGING} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth $RECURSION_DEPTH \
        ${MORE_PARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
    if [ ! "$DEBUG" = true ]
    then
    	echo "DEBUG is $DEBUG, deleting opentelemetry logging file"
    	rm ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
    fi
}

function runOpenTelemetryZipkin {
    # OpenTelemetry Instrumentation Zipkin
    k=`expr ${k} + 1`
    startZipkin
    info " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
    echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}/OpenTelemetry.log
    ${JAVA_BIN} ${JAVA_ARGS_OPENTELEMETRY_ZIPKIN} ${JAR} \
        --output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads ${THREADS} \
        --recursion-depth $RECURSION_DEPTH \
        ${MORE_PARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
    stopBackgroundProcess
    sleep $SLEEP_TIME
}

function runOpenTelemetryJaeger {
	# OpenTelemetry Instrumentation Jaeger
	k=`expr ${k} + 1`
	startJaeger
	info " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
	echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}/OpenTelemetry.log
	${JAVA_BIN} ${JAVA_ARGS_OPENTELEMETRY_JAEGER} ${JAR} \
		--output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
		--total-calls ${TOTAL_NUM_OF_CALLS} \
		--method-time ${METHOD_TIME} \
		--total-threads ${THREADS} \
		--recursion-depth $RECURSION_DEPTH \
		${MORE_PARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
	stopBackgroundProcess
	sleep $SLEEP_TIME
}

function runOpenTelemetryPrometheus {
	# OpenTelemetry Instrumentation Prometheus
	k=`expr ${k} + 1`
	startPrometheus
	info " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]}
	echo " # ${i}.$RECURSION_DEPTH.${k} "${TITLE[$k]} >>${BASE_DIR}/OpenTelemetry.log
	${JAVA_BIN} ${JAVA_ARGS_OPENTELEMETRY_PROMETHEUS} ${JAR} \
		--output-filename ${RAWFN}-${i}-$RECURSION_DEPTH-${k}.csv \
		--total-calls ${TOTAL_NUM_OF_CALLS} \
		--method-time ${METHOD_TIME} \
		--total-threads ${THREADS} \
		--recursion-depth $RECURSION_DEPTH \
		${MORE_PARAMS} &> ${RESULTS_DIR}/output_"$i"_"$RECURSION_DEPTH"_$k.txt
	stopBackgroundProcess
	sleep $SLEEP_TIME
}

# end
