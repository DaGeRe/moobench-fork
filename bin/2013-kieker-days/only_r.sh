#!/bin/bash

JAVABIN=""

RSCRIPTDIR=bin/r-scripts/
BASEDIR=./
RESULTSDIR="${BASEDIR}tmp/ffi-exp/"

SLEEPTIME=30            ## 30
NUM_LOOPS=10            ## 10
THREADS=1               ## 1
RECURSIONDEPTH=10       ## 10
TOTALCALLS=20000000     ## 20000000
METHODTIME=0            ## 0

RAWFN="${RESULTSDIR}raw"

# Timeseries
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTSDIR}results-timeseries.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTALCALLS}
tsconf.min=0
tsconf.max=25
source("${RSCRIPTDIR}timeseries.r")
EOF
# Timeseries-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTSDIR}results-timeseries-average.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTALCALLS}
tsconf.min=0
tsconf.max=25
source("${RSCRIPTDIR}timeseries-average.r")
EOF
# Throughput
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTSDIR}results-throughput.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTALCALLS}
source("${RSCRIPTDIR}throughput.r")
EOF
# Throughput-Average
R --vanilla --silent <<EOF
results_fn="${RAWFN}"
output_fn="${RESULTSDIR}results-throughput-average.pdf"
configs.loop=${NUM_LOOPS}
configs.recursion=c(${RECURSIONDEPTH})
configs.labels=c("No Probe","Deactivated Probe","Collecting Data","TCP Writer","Reconstruction","Reduction")
configs.colors=c("black","red","blue","green","yellow","purple")
results.count=${TOTALCALLS}
source("${RSCRIPTDIR}throughput-average.r")
EOF
