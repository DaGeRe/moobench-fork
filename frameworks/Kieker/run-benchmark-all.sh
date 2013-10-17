#!/bin/bash

SLEEPTIME=30            ## 30
NUM_LOOPS=10            ## 10
THREADS=1               ## 1
RECURSIONDEPTH=10       ## 10
TOTALCALLS=2000000      ## 2000000
METHODTIME=0            ## 0
MOREPARAMS=""
#MOREPARAMS="${MOREPARAMS} --quickstart"

source bin/benchmark-disk-writer-1.8-oer.sh
source bin/benchmark-disk-writer-1.7-oer.sh
source bin/benchmark-disk-writer-1.6-oer.sh
source bin/benchmark-disk-writer-1.5-oer.sh
source bin/benchmark-disk-writer-1.4-oer.sh
source bin/benchmark-disk-writer-1.3-oer.sh
source bin/benchmark-disk-writer-1.2-oer.sh
source bin/benchmark-disk-writer-1.1-oer.sh
source bin/benchmark-disk-writer-1.0-oer.sh
source bin/benchmark-disk-writer-0.95a-oer.sh
source bin/benchmark-disk-writer-0.91-oer.sh

source bin/benchmark-disk-writer-1.8-event.sh
source bin/benchmark-disk-writer-1.7-event.sh
source bin/benchmark-disk-writer-1.6-event.sh
source bin/benchmark-disk-writer-1.5-event.sh
