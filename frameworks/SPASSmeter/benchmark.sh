#!/bin/bash

JAVABIN=""

RSCRIPTDIR=r/
BASEDIR=./
RESULTSDIR="${BASEDIR}tmp/results-spassmeter/"

SLEEPTIME=30           ## 30
NUM_LOOPS=10           ## 10
THREADS=1              ## 1
RECURSIONDEPTH=10      ## 10
TOTALCALLS=2000000     ## 2000000
METHODTIME=500000      ## 500000

#MOREPARAMS="--quickstart"
MOREPARAMS="${MOREPARAMS}"

TIME=`expr ${METHODTIME} \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} + ${SLEEPTIME} \* 4 \* ${NUM_LOOPS}  \* ${RECURSIONDEPTH} + 50 \* ${TOTALCALLS} / 1000000000 \* 4 \* ${RECURSIONDEPTH} \* ${NUM_LOOPS} `
echo "Experiment will take circa ${TIME} seconds."

echo "Removing and recreating '$RESULTSDIR'"
(rm -rf ${RESULTSDIR}) && mkdir ${RESULTSDIR}
mkdir ${RESULTSDIR}stat/

# Clear spassmeter.log and initialize logging
rm -f ${BASEDIR}spassmeter.log
touch ${BASEDIR}spassmeter.log
mkdir ${BASEDIR}logs/

RAWFN="${RESULTSDIR}raw"

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -d64"
JAVAARGS="${JAVAARGS} -Xms1G -Xmx4G"
JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar"

JAVAARGS_NOINSTR="${JAVAARGS}"
JAVAARGS_LTW="${JAVAARGS} -javaagent:${BASEDIR}lib/linux/spass-meter-ia.jar=xmlconfig=${BASEDIR}lib/config.xml,out=${RESULTSDIR}spassmeter.txt"

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
    echo "## Starting iteration ${i}/${NUM_LOOPS}" >>${BASEDIR}spassmeter.log

    # No instrumentation
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} No instrumentation"
    echo " # ${i}.${j}.${k} No instrumentation" >>${BASEDIR}spassmeter.log
    sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${JAVAARGS_NOINSTR} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}spassmeter.log
    echo >>${BASEDIR}spassmeter.log
    sync
    sleep ${SLEEPTIME}

    # SPASSmeter
    k=`expr ${k} + 1`
    echo " # ${i}.${j}.${k} SPASSmeter"
    echo " # ${i}.${j}.${k} SPASSmeter" >>${BASEDIR}spassmeter.log
    sar -o ${RESULTSDIR}stat/sar-${i}-${j}-${k}.data 5 2000 1>/dev/null 2>&1 &
    ${JAVABIN}java ${JAVAARGS_LTW} ${JAR} \
        --output-filename ${RAWFN}-${i}-${j}-${k}.csv \
        --totalcalls ${TOTALCALLS} \
        --methodtime ${METHODTIME} \
        --totalthreads ${THREADS} \
        --recursiondepth ${j} \
        ${MOREPARAMS}
    kill %sar
    [ -f ${BASEDIR}hotspot.log ] && mv ${BASEDIR}hotspot.log ${RESULTSDIR}hotspot-${i}-${j}-${k}.log
    echo >>${BASEDIR}spassmeter.log
    echo >>${BASEDIR}spassmeter.log
    sync
    sleep ${SLEEPTIME}

done
zip -jqr ${RESULTSDIR}stat.zip ${RESULTSDIR}stat
rm -rf ${RESULTSDIR}stat/
mv ${BASEDIR}spassmeter.log ${RESULTSDIR}spassmeter.log
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
configs.labels=c("No Probe","SPASSmeter")
configs.colors=c("black","red")
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
configs.labels=c("No Probe","SPASSmeter")
configs.colors=c("black","red")
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
configs.labels=c("No Probe","SPASSmeter")
configs.colors=c("black","red")
results.count=${TOTALCALLS}
results.skip=${TOTALCALLS}*3/4
source("${RSCRIPTDIR}stats.r")
EOF

## Clean up raw results
zip -jqr ${RESULTSDIR}results.zip ${RAWFN}*
rm -f ${RAWFN}*
[ -f ${BASEDIR}nohup.out ] && cp ${BASEDIR}nohup.out ${RESULTSDIR}
[ -f ${BASEDIR}nohup.out ] && > ${BASEDIR}nohup.out
