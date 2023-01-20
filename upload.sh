#!/bin/bash

#
# Kieker moobench upload script
#
# Usage: upload.sh

# configure base dir
BASE_DIR=$(cd "$(dirname "$0")"; pwd)

KEYSTORE="$1"
UPDATE_SITE_URL="$2"

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
checkFile keystore "${KEYSTORE}"

if [ "${UPDATE_SITE_URL}" == "" ] ; then
	error "Missing UPDATE_SITE_URL"
	information "Usage: $0 KEYSTORE UPDATE_SITE_URL"
	exit 1
fi

mkdir results
cd results
sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}/kieker-java-log.yaml
sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}/kieker-python-log.yaml
sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}/OpenTelemetry-log.yaml
sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}/inspectIT-log.yaml
cd ..
"${COMPILE_RESULTS_BIN}" -i *-results.yaml -l results -c results -t results -w 100
cd results
echo "put *.yaml" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
echo "put *.html" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
echo "put *.json" | sftp -oNoHostAuthenticationForLocalhost=yes -oStrictHostKeyChecking=no -oUser=repo  -F /dev/null -i ${KEYSTORE} ${UPDATE_SITE_URL}
cd ..
# end
