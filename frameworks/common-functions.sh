#!/bin/bash

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

function getKiekerAgent() {
	echo "Checking whether Kieker is present in $AGENT"
	if [ ! -f $AGENT ]
	then
		# get agent
		export VERSION_PATH=`curl "https://oss.sonatype.org/service/local/repositories/snapshots/content/net/kieker-monitoring/kieker/" | grep '<resourceURI>' | sed 's/ *<resourceURI>//g' | sed 's/<\/resourceURI>//g' | grep '/$'`
		export AGENT_PATH=`curl "${VERSION_PATH}" | grep 'aspectj.jar</resourceURI' | sort | sed 's/ *<resourceURI>//g' | sed 's/<\/resourceURI>//g' | tail -1`
		curl "${AGENT_PATH}" > "${AGENT}"
	fi
}

# Initialize all unset parameters
if [ -z $SLEEP_TIME ]; then
	SLEEP_TIME=30           ## 30
fi
if [ -z $NUM_OF_LOOPS ]; then
	NUM_OF_LOOPS=10           ## 10
fi
if [ -z $THREADS ]; then
	THREADS=1              ## 1
fi
if [ -z $RECURSION_DEPTH ]; then
	RECURSION_DEPTH=10      ## 10
fi
if [ -z $TOTAL_NUM_OF_CALLS ]; then
	TOTAL_NUM_OF_CALLS=2000000     ## 2000000
fi
if [ -z $METHOD_TIME ]; then
	METHOD_TIME=0      ## 500000
fi
if [ -z $DEBUG ]; then
	DEBUG=false		## false
fi
