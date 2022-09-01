/**
 * 
 */
package moobench.tools.results;

import moobench.tools.results.data.Chart;
import teetime.stage.basic.AbstractFilter;

/**
 * @author reiner
 *
 */
public class TailChartStage extends AbstractFilter<Chart> {

	private Integer window;

	public TailChartStage(Integer window) {
		this.window = window;
	}

	@Override
	protected void execute(Chart chart) throws Exception {
		if (window != null) {
			int size = chart.getValues().size();
			if (size > window) {
				Chart newChart = new Chart(chart.getName());
				newChart.getHeaders().addAll(chart.getHeaders());
				for (int i = size - window; i < size;i++) {
					newChart.getValues().add(chart.getValues().get(i));
				}
				this.outputPort.send(newChart);
			} else {
				this.outputPort.send(chart);
			}
		} else {
			this.outputPort.send(chart);
		}
	}

}
