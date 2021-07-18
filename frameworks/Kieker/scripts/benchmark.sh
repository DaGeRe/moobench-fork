#!/bin/bash

# configure base dir
BASE_DIR=$(cd "$(dirname "$0")"; pwd)

if [ ! -d "${BASE_DIR}" ] ; then
	echo "Base directory ${BASE_DIR} does not exist."
	exit 1
fi

# load configuration and common functions
if [ -f "${BASE_DIR}/config" ] ; then
	. ${BASE_DIR}/config
else
	echo "Missing configuration: ${BASE_DIR}/config"
	exit 1
fi
if [ -f "${BASE_DIR}/common-functions" ] ; then
	. ${BASE_DIR}/common-functions
else
	echo "Missing configuration: ${BASE_DIR}/common-functions"
	exit 1
fi


# check command line parameters
if [ "$1" == "" ] ; then
	MODE="execute"
else
	if [ "$1" == "execute" ] ; then
		MODE="execute"
	else
		mode="test"
	fi
	OPTION="$2"
fi

# test input parameters and configuration
#checkFile R-script "${RSCRIPT_PATH}"
checkDirectory DATA_DIR "${DATA_DIR}" create

PARENT=`dirname "${RESULTS_DIR}"`
checkDirectory result-base "$PARENT"
checkFile ApsectJ-Agent "${AGENT}"
checkFile moobench "${BENCHMARK}"

information "----------------------------------"
information "Running benchmark..."
information "----------------------------------"

FIXED_PARAMETERS="--quickstart -a moobench.application.MonitoredClassSimple"

TIME=`expr ${METHOD_TIME} \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} + ${SLEEP_TIME} \* 4 \* ${NUM_OF_LOOPS}  \* ${RECURSION_DEPTH} + 50 \* ${TOTAL_NUM_OF_CALLS} / 1000000000 \* 4 \* ${RECURSION_DEPTH} \* ${NUM_OF_LOOPS} `
information "Experiment will take circa ${TIME} seconds."

information "Removing and recreating '$RESULTS_DIR'"
(rm -rf ${RESULTS_DIR}) && mkdir -p ${RESULTS_DIR}

# Clear kieker.log and initialize logging
rm -f ${DATA_DIR}/kieker.log
touch ${DATA_DIR}/kieker.log

RAWFN="${RESULTS_DIR}/raw"

# general server arguments
JAVA_ARGS="-server"
JAVA_ARGS="${JAVA_ARGS} -Xms1G -Xmx2G"

JAVA_OPTS="${FIXED_PARAMETERS}"

LTW_ARGS="-javaagent:${AGENT} -Dorg.aspectj.weaver.showWeaveInfo=false -Daj.weaving.verbose=false -Dkieker.monitoring.skipDefaultAOPConfiguration=true -Dorg.aspectj.weaver.loadtime.configuration=${AOP}"

KIEKER_ARGS="-Dlog4j.configuration=log4j.cfg -Dkieker.monitoring.name=KIEKER-BENCHMARK -Dkieker.monitoring.adaptiveMonitoring.enabled=false -Dkieker.monitoring.periodicSensorsExecutorPoolSize=0"

# JAVA_ARGS used to configure and setup a specific writer
declare -a WRITER_CONFIG
# Receiver setup if necessary
declare -a RECEIVER
# Title
declare -a TITLE

# Configurations
TITLE[0]="No instrumentation"
WRITER_CONFIG[0]=""

TITLE[1]="Deactivated probe"
WRITER_CONFIG[1]="-Dkieker.monitoring.enabled=false -Dkieker.monitoring.writer=kieker.monitoring.writer.dump.DumpWriter"

TITLE[2]="No logging (null writer)"
WRITER_CONFIG[2]="-Dkieker.monitoring.enabled=true -Dkieker.monitoring.writer=kieker.monitoring.writer.dump.DumpWriter"

TITLE[3]="Logging (Generic Text)"
WRITER_CONFIG[3]="-Dkieker.monitoring.enabled=true -Dkieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter -Dkieker.monitoring.writer.filesystem.FileWriter.logStreamHandler=kieker.monitoring.writer.filesystem.TextLogStreamHandler -Dkieker.monitoring.writer.filesystem.FileWriter.customStoragePath=${DATA_DIR}/"

TITLE[4]="Logging (Generic Bin)"
WRITER_CONFIG[4]="-Dkieker.monitoring.enabled=true -Dkieker.monitoring.writer=kieker.monitoring.writer.filesystem.FileWriter -Dkieker.monitoring.writer.filesystem.FileWriter.logStreamHandler=kieker.monitoring.writer.filesystem.BinaryLogStreamHandler -Dkieker.monitoring.writer.filesystem.FileWriter.bufferSize=8192 -Dkieker.monitoring.writer.filesystem.FileWriter.customStoragePath=${DATA_DIR}/"

TITLE[5]="Logging (Single TCP)"
WRITER_CONFIG[5]="-Dkieker.monitoring.writer=kieker.monitoring.writer.tcp.SingleSocketTcpWriter -Dkieker.monitoring.writer.tcp.SingleSocketTcpWriter.port=2345"
#RECEIVER[5]="${BASE_DIR}/collector-2.0/bin/collector -p 2345"
RECEIVER[5]="${BASE_DIR}/receiver/bin/receiver 2345"

# Create R labels
LABELS=""
for I in "${TITLE[@]}" ; do
	title="$I"
	if [ "$LABELS" == "" ] ; then
		LABELS="\"$title\""
	else
		LABELS="${LABELS}, \"$title\""
	fi
done

## Write configuration
uname -a >${RESULTS_DIR}/configuration.txt
${JAVA_BIN} ${JAVA_ARGS} -version 2>>${RESULTS_DIR}/configuration.txt
cat << EOF >>${RESULTS_DIR}/configuration.txt
JAVA_ARGS: ${JAVA_ARGS}

Runtime: circa ${TIME} seconds

SLEEP_TIME=${SLEEP_TIME}
NUM_OF_LOOPS=${NUM_OF_LOOPS}
TOTAL_NUM_OF_CALLS=${TOTAL_NUM_OF_CALLS}
METHOD_TIME=${METHOD_TIME}
RECURSION_DEPTH=${RECURSION_DEPTH}
EOF

sync

#################################
# function: execute an experiment
#
# $1 = i iterator
# $2 = j iterator
# $3 = k iterator
# $4 = title
# $5 = writer parameters
function execute-experiment() {
    loop="$1"
    recursion="$2"
    index="$3"
    title="$4"
    kieker_parameters="$5"

    information " # recursion=${recursion} loop=${loop} writer=${index} ${title}"
    echo " # ${loop}.${recursion}.${index} ${title}" >> ${DATA_DIR}/kieker.log

    if [  "${kieker_parameters}" = "" ] ; then
       BENCHMARK_OPTS=${JAVA_ARGS}
    else
       BENCHMARK_OPTS="${JAVA_ARGS} ${LTW_ARGS} ${KIEKER_ARGS} ${kieker_parameters}"
    fi

    ${BENCHMARK} ${BENCHMARK_OPTS} moobench.benchmark.BenchmarkMain \
    	--application moobench.application.MonitoredClassSimple \
        --output-filename ${RAWFN}-${loop}-${recursion}-${index}.csv \
        --total-calls ${TOTAL_NUM_OF_CALLS} \
        --method-time ${METHOD_TIME} \
        --total-threads 1 \
        --recursion-depth ${recursion} &> benchmark_${loop}.txt

    rm -rf ${DATA_DIR}/kieker-*

    [ -f ${DATA_DIR}/hotspot.log ] && mv ${DATA_DIR}/hotspot.log ${RESULTS_DIR}hotspot-${loop}-${recursion}-${index}.log
    echo >> ${DATA_DIR}/kieker.log
    echo >> ${DATA_DIR}/kieker.log
    sync
    sleep ${SLEEP_TIME}
}

function execute-benchmark-body() {
  index="$1"
  loop="$2"
  recursion="$3"
  if [[ ${RECEIVER[$index]} ]] ; then
     echo "receiver ${RECEIVER[$index]}"
     ${RECEIVER[$index]} & #>> ${DATA_DIR}/kieker.receiver-$i-$index.log &
     RECEIVER_PID=$!
     echo "PID $RECEIVER_PID"
  fi

  execute-experiment "$loop" "$recursion" "$index" "${TITLE[$index]}" "${WRITER_CONFIG[$index]}"

  if [[ $RECEIVER_PID ]] ; then
     kill -TERM $RECEIVER_PID
     unset RECEIVER_PID
  fi
}

function getSum {
  awk '{sum += $1; square += $1^2} END {print "Average: "sum/NR" Standard Deviation: "sqrt(square / NR - (sum/NR)^2)" Count: "NR}'
}

function printIntermediaryResults {
   for ((index=0;index<${#WRITER_CONFIG[@]};index+=1)); do
      echo -n "Intermediary results $TITLE[$index] "
      cat results-kieker/raw-*-${RECURSION_DEPTH}-${index}.csv | awk -F';' '{print $2}' | getSum
   done
}

## Execute Benchmark
function execute-benchmark() {
  for ((loop=1;loop<=${NUM_OF_LOOPS};loop+=1)); do
    recursion=${RECURSION_DEPTH}

    information "## Starting iteration ${i}/${NUM_OF_LOOPS}"
    echo "## Starting iteration ${i}/${NUM_OF_LOOPS}" >>${DATA_DIR}/kieker.log

    for ((index=0;index<${#WRITER_CONFIG[@]};index+=1)); do
      execute-benchmark-body $index $loop $recursion
    done
    
    printIntermediaryResults
  done

  mv ${DATA_DIR}/kieker.log ${RESULTS_DIR}/kieker.log
  [ -f ${RESULTS_DIR}/hotspot-1-${RECURSION_DEPTH}-1.log ] && grep "<task " ${RESULTS_DIR}/hotspot-*.log > ${RESULTS_DIR}/log.log
  [ -f ${DATA_DIR}/errorlog.txt ] && mv ${DATA_DIR}/errorlog.txt ${RESULTS_DIR}
}

## Generate Results file
function run-r() {
R --vanilla --silent << EOF
results_fn="${RAWFN}"
outtxt_fn="${RESULTS_DIR}/results-text.txt"
outcsv_fn="${RESULTS_DIR}/results-text.csv"
configs.loop=${NUM_OF_LOOPS}
configs.recursion=${RECURSION_DEPTH}
configs.labels=c($LABELS)
results.count=${TOTAL_NUM_OF_CALLS}
results.skip=${TOTAL_NUM_OF_CALLS}/2
source("${RSCRIPT_PATH}")
EOF
}

## Clean up raw results
function cleanup-results() {
  zip -jqr ${RESULTS_DIR}/results.zip ${RAWFN}*
  rm -f ${RAWFN}*
  [ -f ${DATA_DIR}/nohup.out ] && cp ${DATA_DIR}/nohup.out ${RESULTS_DIR}
  [ -f ${DATA_DIR}/nohup.out ] && > ${DATA_DIR}/nohup.out
}

## Execute benchmark
if [ "$MODE" == "execute" ] ; then
   if [ "$OPTION" == "" ] ; then
     execute-benchmark
   else
     execute-benchmark-body $OPTION 1 1
   fi
   run-r
   cleanup-results
else
   execute-benchmark-body $OPTION 1 1
fi

information "Done."

# end
