package moobench.tools.results.data;

import java.util.ArrayList;
import java.util.List;

public class Chart {
	
	final String name;
	final List<String> headers = new ArrayList<>();
	final List<ValueTuple> values = new ArrayList<ValueTuple>();
	
	public Chart(String name) {
		this.name = name;
	}
	
	public String getName() {
		return name;
	}

	public List<String> getHeaders() {
		return headers;
	}
	
	public List<ValueTuple> getValues() {
		return values;
	}	
}
