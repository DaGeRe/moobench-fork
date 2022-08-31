/**
 * 
 */
package moobench.tools.results.data;

import java.util.HashMap;
import java.util.Map;

/**
 * @author Reiner Jung
 *
 */
public class Experiment {

	double timestamp;
	Map<String,Measurements> measurements = new HashMap<>();
	
	public double getTimestamp() {
		return timestamp;
	}
	
	public void setTimestamp(double timestamp) {
		this.timestamp = timestamp;
	}
	
	public Map<String,Measurements> getMeasurements() {
		return measurements;
	}
	public void setMeasurements(Map<String,Measurements> measurements) {
		this.measurements = measurements;
	}
	
	@Override
	public String toString() {
		return String.format("time: %f, measurements: %d\n", timestamp, measurements.size());
	}
	
}
