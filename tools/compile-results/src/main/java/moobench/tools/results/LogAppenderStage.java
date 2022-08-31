/**
 * 
 */
package moobench.tools.results;

import java.util.Map;

import moobench.tools.results.data.Experiment;
import moobench.tools.results.data.ExperimentLog;
import teetime.framework.AbstractStage;
import teetime.framework.InputPort;
import teetime.framework.OutputPort;

/**
 * @author Reiner Jung
 * @since 1.3.0
 */
public class LogAppenderStage extends AbstractStage {

	private final InputPort<ExperimentLog> newDataInputPort = this.createInputPort(ExperimentLog.class);
	private final InputPort<ExperimentLog> logInputPort = this.createInputPort(ExperimentLog.class);
	private final OutputPort<ExperimentLog> outputPort = this.createOutputPort(ExperimentLog.class);
	
	private Map<String,ExperimentLog> logs;

	public InputPort<ExperimentLog> getNewDataInputPort() {
		return newDataInputPort;
	}
	
	public InputPort<ExperimentLog> getLogInputPort() {
		return logInputPort;
	}
	
	public OutputPort<ExperimentLog> getOutputPort() {
		return outputPort;
	}
	
	@Override
	protected void execute() throws Exception {
		ExperimentLog newData = this.newDataInputPort.receive();
		if (newData != null) {
			appendData(newData);
		}
		ExperimentLog logData = this.logInputPort.receive();
		if (logData != null) {
			appendData(logData);
		}
	}
	
	private void appendData(ExperimentLog newData) {
		ExperimentLog presentLog = logs.get(newData.getKind());
		if (presentLog != null) {
			for (Experiment experiment : newData.getExperiments()) {
				presentLog.getExperiments().add(experiment);
			}
		}
	}
	
	@Override
	protected void onTerminating() {
		for (ExperimentLog experimentLog : logs.values()) {
			this.outputPort.send(experimentLog);
		}
		super.onTerminating();
	}
}
