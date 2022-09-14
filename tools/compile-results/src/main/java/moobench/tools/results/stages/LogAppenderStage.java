/**
 * 
 */
package moobench.tools.results.stages;

import java.util.HashMap;
import java.util.Map;

import moobench.tools.results.data.Experiment;
import moobench.tools.results.data.ExperimentLog;
import teetime.framework.AbstractConsumerStage;
import teetime.framework.OutputPort;

/**
 * @author Reiner Jung
 * @since 1.3.0
 */
public class LogAppenderStage extends AbstractConsumerStage<ExperimentLog> {

	private final OutputPort<ExperimentLog> outputPort = this.createOutputPort(ExperimentLog.class);
	
	private Map<String,ExperimentLog> logs = new HashMap<>();
	
	public OutputPort<ExperimentLog> getOutputPort() {
		return outputPort;
	}
	
	@Override
	protected void execute(ExperimentLog log) throws Exception {
		ExperimentLog presentLog = logs.get(log.getKind());
		if (presentLog != null) {
			for (Experiment experiment : log.getExperiments()) {
				presentLog.getExperiments().add(experiment);
			}
		} else {
			logs.put(log.getKind(), log);
		}
	}
	
	@Override
	protected void onTerminating() {
		for (ExperimentLog experimentLog : logs.values()) {
			experimentLog.sort();
			this.outputPort.send(experimentLog);
		}
		super.onTerminating();
	}
}
