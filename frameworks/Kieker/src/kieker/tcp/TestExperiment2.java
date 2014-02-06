/***************************************************************************
 * Copyright 2014 Kieker Project (http://kieker-monitoring.net)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ***************************************************************************/

package kieker.tcp;

import java.util.concurrent.TimeUnit;

import kieker.analysis.AnalysisController;
import kieker.analysis.IAnalysisController;
import kieker.analysis.exception.AnalysisConfigurationException;
import kieker.analysis.plugin.filter.flow.EventRecordTraceReconstructionFilter;
import kieker.analysis.plugin.filter.forward.AnalysisThroughputFilter;
import kieker.analysis.plugin.filter.forward.TeeFilter;
import kieker.analysis.plugin.reader.tcp.TCPReader;
import kieker.analysis.plugin.reader.timer.TimeReader;
import kieker.common.configuration.Configuration;
import kieker.common.logging.Log;
import kieker.common.logging.LogFactory;

// Command-Line:
// java -javaagent:lib/kieker-1.8-SNAPSHOT_aspectj.jar -Dkieker.monitoring.writer=kieker.monitoring.writer.tcp.TCPWriter -Dkieker.monitoring.writer.tcp.TCPWriter.QueueFullBehavior=1 -jar dist\OverheadEvaluationMicrobenchmark.jar --recursiondepth 10 --totalthreads 1 --methodtime 0 --output-filename raw.csv --totalcalls 10000000
/**
 * 
 * @author Jan Waller
 * 
 * @since 1.8
 */
public final class TestExperiment2 {
	private static final Log LOG = LogFactory.getLog(TestExperiment2.class);

	private TestExperiment2() {}

	public static void main(final String[] args) throws IllegalStateException, AnalysisConfigurationException {
		final IAnalysisController analysisController = new AnalysisController("TCPThroughput");
		TestExperiment2.createAndConnectPlugins(analysisController);
		try {
			analysisController.run();
		} catch (final AnalysisConfigurationException ex) {
			TestExperiment2.LOG.error("Failed to start the example project.", ex);
		}
	}

	private static void createAndConnectPlugins(final IAnalysisController analysisController) throws IllegalStateException, AnalysisConfigurationException {
		final Configuration readerConfig = new Configuration();
		// readerConfig.setProperty(TCPReader.CONFIG_PROPERTY_NAME_PORT1, 10333);
		// readerConfig.setProperty(TCPReader.CONFIG_PROPERTY_NAME_PORT2, 10334);
		final TCPReader reader = new TCPReader(readerConfig, analysisController);

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
		analysisController.connect(through, AnalysisThroughputFilter.OUTPUT_PORT_NAME_THROUGHPUT, teeFilter, TeeFilter.INPUT_PORT_NAME_EVENTS);
	}
}
