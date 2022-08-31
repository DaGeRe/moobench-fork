package moobench.tools.results.data;

import java.util.ArrayList;
import java.util.List;

public class ExperimentLog {
	
	String kind;
	List<Experiment> experiments = new ArrayList<>();
	
	public String getKind() {
		return kind;
	}
	
	public void setKind(String kind) {
		this.kind = kind;
	}
	
	public List<Experiment> getExperiments() {
		return experiments;
	}

	public void setExperiments(List<Experiment> experiments) {
		this.experiments = experiments;
	}
}
