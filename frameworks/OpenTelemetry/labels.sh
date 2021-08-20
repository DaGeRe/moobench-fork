TITLE[0]="No instrumentation"
TITLE[1]="OpenTelemetry No Logging"
TITLE[2]="OpenTelemetry Logging"
TITLE[3]="OpenTelemetry Zipkin"
MACHINE_TYPE=`uname -m`; 
if [ ${MACHINE_TYPE} == 'x86_64' ]
then
	TITLE[4]="OpenTelemetry Jaeger"
	TITLE[5]="OpenTelemetry Prometheus"
fi
