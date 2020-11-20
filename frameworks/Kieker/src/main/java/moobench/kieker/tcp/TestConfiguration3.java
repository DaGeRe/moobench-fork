package moobench.kieker.tcp;

import java.util.concurrent.TimeUnit;

import kieker.analysis.source.tcp.MultipleConnectionTcpSourceStage;
import teetime.framework.Configuration;

public class TestConfiguration3 extends Configuration {

	public TestConfiguration3(int inputPort, int bufferSize) {
		MultipleConnectionTcpSourceStage source = new MultipleConnectionTcpSourceStage(inputPort, bufferSize, null);
	
		/*
			final Configuration timeConfig = new Configuration();
		final TimeReader timeReader = new TimeReader(timeConfig, analysisController);

		final Configuration configTraceRecon = new Configuration();
		configTraceRecon.setProperty(EventRecordTraceReconstructionFilter.CONFIG_PROPERTY_NAME_TIMEUNIT, TimeUnit.SECONDS.name());
		configTraceRecon.setProperty(EventRecordTraceReconstructionFilter.CONFIG_PROPERTY_NAME_MAX_TRACE_DURATION, "1");
		configTraceRecon.setProperty(EventRecordTraceReconstructionFilter.CONFIG_PROPERTY_NAME_MAX_TRACE_TIMEOUT, "1");
		final EventRecordTraceReconstructionFilter traceRecon = new EventRecordTraceReconstructionFilter(configTraceRecon, analysisController);

		analysisController.connect(reader, TCPReader.OUTPUT_PORT_NAME_RECORDS, traceRecon, EventRecordTraceReconstructionFilter.INPUT_PORT_NAME_TRACE_RECORDS);
		analysisController.connect(timeReader, TimeReader.OUTPUT_PORT_NAME_TIMESTAMPS, traceRecon, EventRecordTraceReconstructionFilter.INPUT_PORT_NAME_TIME_EVENT);

		final Configuration configTraceAggr = new Configuration();
		configTraceAggr.setProperty(TraceAggregationFilter.CONFIG_PROPERTY_NAME_TIMEUNIT, TimeUnit.SECONDS.name());
		configTraceAggr.setProperty(TraceAggregationFilter.CONFIG_PROPERTY_NAME_MAX_COLLECTION_DURATION, "1");
		final TraceAggregationFilter traceAggr = new TraceAggregationFilter(configTraceAggr, analysisController);

		analysisController.connect(traceRecon, EventRecordTraceReconstructionFilter.OUTPUT_PORT_NAME_TRACE_VALID, traceAggr,
				TraceAggregationFilter.INPUT_PORT_NAME_TRACES);
		analysisController.connect(timeReader, TimeReader.OUTPUT_PORT_NAME_TIMESTAMPS, traceAggr, TraceAggregationFilter.INPUT_PORT_NAME_TIME_EVENT);

		final Configuration confTeeFilter = new Configuration();
		confTeeFilter.setProperty(TeeFilter.CONFIG_PROPERTY_NAME_STREAM, TeeFilter.CONFIG_PROPERTY_VALUE_STREAM_STDOUT);
		// confTeeFilter.setProperty(TeeFilter.CONFIG_PROPERTY_NAME_STREAM, TeeFilter.CONFIG_PROPERTY_VALUE_STREAM_NULL);
		final TeeFilter teeFilter = new TeeFilter(confTeeFilter, analysisController);
		analysisController.connect(traceAggr, TraceAggregationFilter.OUTPUT_PORT_NAME_TRACES, teeFilter, TeeFilter.INPUT_PORT_NAME_EVENTS);
*/
	}
}
