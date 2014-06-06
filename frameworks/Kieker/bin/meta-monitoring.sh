#!/bin/bash

JAVABIN=""

BASEDIR=./
RESULTSDIR="${BASEDIR}results/"

THREADS=1            ## 1
RECURSIONDEPTH=10    ## 10
TOTALCALLS=20000     ## 20000
METHODTIME=0         ## 0

#MOREPARAMS="--quickstart"
MOREPARAMS="${MOREPARAMS} -r kieker.Logger -a mooBench.monitoredApplication.MonitoredClassManualInstrumentation"

echo "Removing and recreating '$RESULTSDIR'"
(rm -rf ${RESULTSDIR}) && mkdir ${RESULTSDIR}

JAVAARGS="-server"
JAVAARGS="${JAVAARGS} -d64"
JAVAARGS="${JAVAARGS} -Xms1G -Xmx4G"
#JAVAARGS="${JAVAARGS} -verbose:gc -XX:+PrintCompilation"
#JAVAARGS="${JAVAARGS} -XX:+PrintInlining"
#JAVAARGS="${JAVAARGS} -XX:+UnlockDiagnosticVMOptions -XX:+LogCompilation"
#JAVAARGS="${JAVAARGS} -Djava.compiler=NONE"
JAR="-jar MooBench.jar"
JAVAAGENT="-javaagent:lib/kicker-1.10_aspectj.jar"

JAVAARGS="${JAVAARGS} -Dkieker.monitoring.writer.filesystem.AsyncFsWriter.customStoragePath=${RESULTSDIR}"
JAVAARGS="${JAVAARGS} -Dkicker.monitoring.writer.filesystem.AsyncBinaryFsWriter.customStoragePath=${RESULTSDIR}"
JAVAARGS="${JAVAARGS} -Dkicker.monitoring.debug=true -Dkicker.monitoring.skipDefaultAOPConfiguration=true"

## Write configuration
uname -a >${RESULTSDIR}configuration.txt
${JAVABIN}java ${JAVAARGS} -version 2>>${RESULTSDIR}configuration.txt
echo "JAVAARGS: ${JAVAARGS}" >>${RESULTSDIR}configuration.txt
echo "" >>${RESULTSDIR}configuration.txt
echo "TOTALCALLS=${TOTALCALLS}" >>${RESULTSDIR}configuration.txt
echo "METHODTIME=${METHODTIME}" >>${RESULTSDIR}configuration.txt
echo "THREADS=${THREADS}" >>${RESULTSDIR}configuration.txt
echo "RECURSIONDEPTH=${RECURSIONDEPTH}" >>${RESULTSDIR}configuration.txt
sync

${JAVABIN}java ${JAVAARGS} ${JAVAAGENT} ${JAR} \
    --output-filename ${RESULTSDIR}raw.csv \
    --totalcalls ${TOTALCALLS} \
    --methodtime ${METHODTIME} \
    --totalthreads ${THREADS} \
    --recursiondepth ${RECURSIONDEPTH} \
    ${MOREPARAMS}
sync
mv ${BASEDIR}kieker.log ${RESULTSDIR}kieker.log

[ -f ${BASEDIR}nohup.out ] && cp ${BASEDIR}nohup.out ${RESULTSDIR}
zip -qr ${BASEDIR}results.zip ${RESULTSDIR}*
[ -f ${BASEDIR}nohup.out ] && > ${BASEDIR}nohup.out
