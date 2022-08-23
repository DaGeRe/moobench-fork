#!/bin/bash

#
# Kieker moobench setup script
#
# Usage: setup.sh

# configure base dir
BASE_DIR=$(cd "$(dirname "$0")"; pwd)

#
# source functionality
#

if [ ! -d "${BASE_DIR}" ] ; then
        echo "Base directory ${BASE_DIR} does not exist."
        exit 1
fi

# load configuration and common functions
if [ -f "${BASE_DIR}/config.rc" ] ; then
        source "${BASE_DIR}/config.rc"
else
        echo "Missing configuration: ${BASE_DIR}/config.rc"
        exit 1
fi

if [ -f "${BASE_DIR}/common-functions.sh" ] ; then
        source "${BASE_DIR}/common-functions.sh"
else
        echo "Missing library: ${BASE_DIR}/common-functions.sh"
        exit 1
fi

cd "${BASE_DIR}"

./gradlew build

checkFile moobench "${MOOBENCH_ARCHIVE}"
tar -xpf "${MOOBENCH_ARCHIVE}"
MOOBENCH_BIN="${BASE_DIR}/benchmark/bin/benchmark"

# end
