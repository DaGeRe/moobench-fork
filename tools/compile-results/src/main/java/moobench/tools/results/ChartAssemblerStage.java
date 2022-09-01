/**
 * 
 */
package moobench.tools.results;

import java.util.List;
import java.util.Map;

import moobench.tools.results.data.Chart;
import moobench.tools.results.data.Experiment;
import moobench.tools.results.data.ExperimentLog;
import moobench.tools.results.data.Measurements;
import moobench.tools.results.data.ValueTuple;
import teetime.stage.basic.AbstractTransformation;

/**
 * @author Reiner Jung
 * @since 1.3.0
 *
 */
public class ChartAssemblerStage extends AbstractTransformation<ExperimentLog, Chart> {

	@Override
	protected void execute(ExperimentLog element) throws Exception {
		Chart chart = new Chart(element.getKind());
		for (Experiment experiment : element.getExperiments()) {
			long timestamp = Double.valueOf(experiment.getTimestamp()).longValue();
			ValueTuple tuple = new ValueTuple(timestamp);
			
			addHeaderIfMissing(chart.getHeaders(), experiment.getMeasurements());
			fillInData(chart.getHeaders(), tuple.getValues(), experiment.getMeasurements());
			
			chart.getValues().add(tuple);
		}
		
		this.outputPort.send(chart);
	}

	private void fillInData(List<String> headers, List<Double> values, Map<String, Measurements> measurements) {
		for (String key : headers) {
			Measurements value = measurements.get(key);
			if (value != null) {
				values.add(value.getMean());
			} else
				values.add(Double.NaN);
		}
	}

	private void addHeaderIfMissing(List<String> headers, Map<String, Measurements> measurements) {
		for (String key : measurements.keySet()) {
			if (!headers.stream().anyMatch(header -> header.equals(key))) {
				headers.add(key);
			}
		}		
	}

}
