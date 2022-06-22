#!/bin/bash

JAVABIN=""

R_SCRIPT_DIR=bin/r-scripts/
BASE_DIR=./
RESULTS_DIR="${BASE_DIR}tmp/ffi-exp/"

SLEEP_TIME=30            ## 30
NUM_LOOPS=10            ## 10
THREADS=1               ## 1
RECURSIONDEPTH=10       ## 10
TOTAL_CALLS=20000000     ## 20000000
METHODTIME=0            ## 0

RAWFN="${RESULTS_DIR}raw"

# Timeseries
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-timeseries.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTAL_CALLS}
tsconf.min=0
tsconf.max=25
source("${R_SCRIPT_DIR}timeseries.r")
EOF
# Timeseries-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-timeseries-average.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTAL_CALLS}
tsconf.min=0
tsconf.max=25
source("${R_SCRIPT_DIR}timeseries-average.r")
EOF
# Throughput
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-throughput.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTAL_CALLS}
source("${R_SCRIPT_DIR}throughput.r")
EOF
# Throughput-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTS_DIR}results-throughput-average.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTAL_CALLS}
source("${R_SCRIPT_DIR}throughput-average.r")
EOF
