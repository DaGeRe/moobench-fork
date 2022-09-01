package moobench.tools.results.data;

import java.util.ArrayList;
import java.util.List;

public class ValueTuple {
	
	long timestamp;
	
	List<Double> values = new ArrayList<>();
	
	public ValueTuple(long timestamp) {
		this.timestamp = timestamp;
	}
	
	public long getTimestamp() {
		return timestamp;
	}
	
	public List<Double> getValues() {
		return values;
	}
}
