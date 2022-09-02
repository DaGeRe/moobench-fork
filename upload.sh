#!/bin/bash

#
# Kieker moobench upload script
#
# Usage: upload.sh

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

checkExecutable compile-results "${COMPILE_RESULTS_BIN}"

KEYSTORE="$1"
UPDATE_SITE_RUL="$2"

mkdir results
cd results
sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}/kieker-java.yaml
sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}/kieker-python.yaml
sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}/opentelemetry.yaml
sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}/inspectit.yaml
cd ..
"${COMPILE_RESULTS_BIN}" -i *-results.yaml -l results -t results -j results -w 100
cd results
echo "put *.yaml" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
echo "put *.html" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
echo "put *.json" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
cd ..
# end
