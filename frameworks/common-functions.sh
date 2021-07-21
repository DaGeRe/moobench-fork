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

# Initialize all unset parameters
if [ -z $SLEEPTIME ]; then
	SLEEPTIME=30           ## 30
fi
if [ -z $NUM_LOOPS ]; then
	NUM_LOOPS=10           ## 10
fi
if [ -z $THREADS ]; then
	THREADS=1              ## 1
fi
if [ -z $RECURSIONDEPTH ]; then
	RECURSIONDEPTH=10      ## 10
fi
if [ -z $TOTALCALLS ]; then
	TOTALCALLS=2000000     ## 2000000
fi
if [ -z $METHODTIME ]; then
	METHODTIME=0      ## 500000
fi
if [ -z $DEBUG ]; then
	DEBUG=false		## false
fi
