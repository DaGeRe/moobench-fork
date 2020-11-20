/**
 * 
 */
package moobench.kieker.tcp;

import java.util.concurrent.TimeUnit;

import kieker.analysis.source.tcp.MultipleConnectionTcpSourceStage;
import teetime.framework.Configuration;

/**
 * @author reiner
 *
 */
public class TestConfiguration2 extends Configuration {

	public TestConfiguration2(int inputPort, int bufferSize) {
		MultipleConnectionTcpSourceStage reader = new MultipleConnectionTcpSourceStage(inputPort, bufferSize, null);
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

		final Configuration counterConfig = new Configuration();
		final AnalysisThroughputFilter through = new AnalysisThroughputFilter(counterConfig, analysisController);
		analysisController.connect(traceRecon, EventRecordTraceReconstructionFilter.OUTPUT_PORT_NAME_TRACE_VALID, through,
				AnalysisThroughputFilter.INPUT_PORT_NAME_OBJECTS);
		analysisController.connect(timeReader, TimeReader.OUTPUT_PORT_NAME_TIMESTAMPS, through, AnalysisThroughputFilter.INPUT_PORT_NAME_TIME);

		final Configuration confTeeFilter = new Configuration();
		confTeeFilter.setProperty(TeeFilter.CONFIG_PROPERTY_NAME_STREAM, TeeFilter.CONFIG_PROPERTY_VALUE_STREAM_STDOUT);
		// confTeeFilter.setProperty(TeeFilter.CONFIG_PROPERTY_NAME_STREAM, TeeFilter.CONFIG_PROPERTY_VALUE_STREAM_NULL);
		final TeeFilter teeFilter = new TeeFilter(confTeeFilter, analysisController);
		analysisController.connect(through, AnalysisThroughputFilter.OUTPUT_PORT_NAME_THROUGHPUT, teeFilter, TeeFilter.INPUT_PORT_NAME_EVENTS);*/
	
	}
}
