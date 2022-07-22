#!/bin/bash

#
# Common functions used in scripts.
#

# ensure the script is sourced
if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "Hey, you should source this script, not execute it!"
    exit 1
fi

#
# functions
#

function getSum {
  awk '{sum += $1; square += $1^2} END {print "Average: "sum/NR" Standard Deviation: "sqrt(square / NR - (sum/NR)^2)" Count: "NR}'
}

## Clean up raw results
function cleanup-results() {
  zip -jqr ${RESULTS_DIR}/results.zip ${RAWFN}*
  rm -f ${RAWFN}*
  [ -f ${DATA_DIR}/nohup.out ] && cp ${DATA_DIR}/nohup.out ${RESULTS_DIR}
  [ -f ${DATA_DIR}/nohup.out ] && > ${DATA_DIR}/nohup.out
}

function checkMoobenchApplication() {
	if [ ! -f "MooBench.jar" ]
	then
		echo "MooBench.jar missing; please build it first using ./gradlew assemble in the main folder"
		exit 1
	fi
}

function getKiekerAgent() {
	echo "Checking whether Kieker is present in $AGENT"
	if [ ! -f $AGENT ]
	then
		# get agent
		export VERSION_PATH=`curl "https://oss.sonatype.org/service/local/repositories/snapshots/content/net/kieker-monitoring/kieker/" | grep '<resourceURI>' | sed 's/ *<resourceURI>//g' | sed 's/<\/resourceURI>//g' | grep '/$' | grep -v ".xml" | head -n 1`
		export AGENT_PATH=`curl "${VERSION_PATH}" | grep 'aspectj.jar</resourceURI' | sort | sed 's/ *<resourceURI>//g' | sed 's/<\/resourceURI>//g' | tail -1`
		curl "${AGENT_PATH}" > "${AGENT}"
		
		if [ ! -f $AGENT ] | [ -s $AGENT ]
		then
			echo "Kieker download from $AGENT_PATH failed; please asure that a correct Kieker AspectJ file is present!"
		fi
		
	fi
}

function getInspectItAgent() {
	if [ ! -d agent ]
	then
		mkdir agent
		cd agent
		wget https://github.com/inspectIT/inspectit-ocelot/releases/download/1.11.1/inspectit-ocelot-agent-1.11.1.jar
		cd ..
	fi
}

function getOpentelemetryAgent() {
	if [ ! -f "${BASE_DIR}/lib/opentelemetry-javaagent.jar" ]
	then
		mkdir -p "${BASE_DIR}/lib"
		wget --output-document=${BASE_DIR}/lib/opentelemetry-javaagent.jar \
			https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
	fi
}

function createRLabels() {
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
	echo $LABELS
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

function startZipkin {
	if [ ! -d zipkin ] || [ ! -f zipkin/zipkin.jar ]
	then
		mkdir zipkin
		cd zipkin
		curl -sSL https://zipkin.io/quickstart.sh | bash -s
	else
		cd zipkin
	fi
	java -Xmx6g -jar zipkin.jar &> zipkin.txt &
	pid=$!
	sleep 5
	cd ..
}

function periodicallyCurlPrometheus {
	while [ true ]
	do
		echo "Curling for prometheus simulation..."
		curl localhost:8888/metrics 
		sleep 15
	done
}

function startPrometheus {
	periodicallyCurlPrometheus &
	pid=$!
}

function stopBackgroundProcess {
	kill $pid
}

function writeConfiguration() {
	uname -a >${RESULTS_DIR}/configuration.txt
	${JAVA_BIN} ${JAVA_ARGS} -version 2 >> ${RESULTS_DIR}/configuration.txt
	echo "JAVA_ARGS: ${JAVA_ARGS}" >> ${RESULTS_DIR}/configuration.txt
	echo "" >> ${RESULTS_DIR}/configuration.txt
	echo "Runtime: circa ${TIME} seconds" >> ${RESULTS_DIR}/configuration.txt
	echo "" >> ${RESULTS_DIR}/configuration.txt
	echo "SLEEP_TIME=${SLEEP_TIME}" >> ${RESULTS_DIR}/configuration.txt
	echo "NUM_OF_LOOPS=${NUM_OF_LOOPS}" >> ${RESULTS_DIR}/configuration.txt
	echo "TOTAL_NUM_OF_CALLS=${TOTAL_NUM_OF_CALLS}" >> ${RESULTS_DIR}/configuration.txt
	echo "METHOD_TIME=${METHOD_TIME}" >> ${RESULTS_DIR}/configuration.txt
	echo "THREADS=${THREADS}" >> ${RESULTS_DIR}/configuration.txt
	echo "RECURSION_DEPTH=${RECURSION_DEPTH}" >> ${RESULTS_DIR}/configuration.txt
	sync
}

function printIntermediaryResults {
   for ((index=0;index<${#TITLE[@]};index+=1)); do
      echo -n "Intermediary results "${TITLE[$index]}" "
      cat ${RESULTS_DIR}/raw-*-${RECURSION_DEPTH}-${index}.csv | awk -F';' '{print $2}' | getSum
   done
}

#
# reporting
#

export RED='\033[1;31m'
export WHITE='\033[1;37m'
export YELLOW='\033[1;33m'
export NC='\033[0m'

if [ "$BATCH_MODE" == "yes" ] ; then
	export ERROR="[error]"
	export WARNING="[warning]"
	export INFO="[info]"
else
	export ERROR="${RED}[error]${NC}"
	export WARNING="${YELLOW}[warning]${NC}"
	export INFO="${WHITE}[info]${NC}"
fi

function error() {
	echo -e "${ERROR} $@"
}

function warn() {
	echo -e "${WARNING} $@"
}

function info() {
	echo -e "${INFO} $@"
}

# $1 = NAME, $2 = EXECUTABLE
function checkExecutable() {
	if [ "$2" == "" ] ; then
		error "$1 variable for executable not set."
		exit 1
	fi
	if [ ! -x "$2" ] ; then
		error "$1 not found at: $2"
		exit 1
	fi
}

# $1 = NAME, $2 = FILE
function checkFile() {
	if [ "$2" == "" ] ; then
		error "$1 variable for file not set."
		exit 1
	fi
	if [ ! -f "$2" ] ; then
		if [ "$3" == "clean" ] ; then
			touch "$2"
		else
			error "$1 not found at: $2"
			exit 1
		fi
	else
		if [ "$3" == "clean" ] ; then
			info "$1 recreated, now empty"
			rm -f "$2"
			touch "$2"
		fi
	fi
}

# $1 = NAME, $2 = FILE
function checkDirectory() {
	if [ "$2" == "" ] ; then
		error "$1 directory variable not set."
		exit 1
	fi
	if [ ! -d "$2" ] ; then
		if [ "$3" == "create" ] ; then
			info "$1: directory does not exist, creating it"
			mkdir -p "$2"
		else
			error "$1: directory $2 does not exist."
			exit 1
		fi
	else
		if [ "$3" == "recreate" ] ; then
			info "$1: exists, recreating it"
			rm -rf "$2"
			mkdir -p "$2"
		fi
	fi
}

FRAMEWORK_NAME=$(basename -- "${BASE_DIR}")
RESULTS_DIR="${BASE_DIR}/results-${FRAMEWORK_NAME}"
RAWFN="${RESULTS_DIR}/raw"

# Initialize all unset parameters
if [ -z $SLEEP_TIME ]; then
	SLEEP_TIME=30             ## 30
fi
if [ -z $NUM_OF_LOOPS ]; then
	NUM_OF_LOOPS=10           ## 10
fi
if [ -z $THREADS ]; then
	THREADS=1                 ## 1
fi
if [ -z $RECURSION_DEPTH ]; then
	RECURSION_DEPTH=10        ## 10
fi
if [ -z $TOTAL_NUM_OF_CALLS ]; then
	TOTAL_NUM_OF_CALLS=2000000     ## 2000000
fi
if [ -z $METHOD_TIME ]; then
	METHOD_TIME=0             ## 500000
fi
if [ -z $DEBUG ]; then
	DEBUG=false	  	  ## false
fi
