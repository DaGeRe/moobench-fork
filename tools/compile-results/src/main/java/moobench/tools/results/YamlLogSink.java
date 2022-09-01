package moobench.tools.results;

import java.io.FileWriter;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.nodes.Node;
import org.yaml.snakeyaml.nodes.Tag;
import org.yaml.snakeyaml.representer.Represent;
import org.yaml.snakeyaml.representer.Representer;

import moobench.tools.results.data.ExperimentLog;
import moobench.tools.results.data.Measurements;
import teetime.framework.AbstractConsumerStage;

public class YamlLogSink extends AbstractConsumerStage<ExperimentLog> {

	Path logPath;
	
	public YamlLogSink(Path logPath) {
		this.logPath = logPath;
	}
	
	@Override
	protected void execute(ExperimentLog log) throws Exception {
		Path logPath = this.logPath.resolve(String.format("%s.yaml", log.getKind()));

		Representer representer = new LogRepresenter();
		DumperOptions options = new DumperOptions();
		Yaml yaml = new Yaml(representer, options);
    
	    FileWriter writer = new FileWriter(logPath.toFile());
	    yaml.dump(log, writer);        
	}
	
	private class LogRepresenter extends Representer {
		
		public LogRepresenter() {
	        this.representers.put(Measurements.class, new RepresentMeasurements());
	    }
		
		private class RepresentMeasurements implements Represent {

			@Override
			public Node representData(Object data) {
				Measurements measurements = (Measurements)data;
				
				List<Double> values = new ArrayList<>();
				values.add(measurements.getMean());
				values.add(measurements.getStandardDeviation());
				values.add(measurements.getConvidence());
				values.add(measurements.getLowerQuartile());
				values.add(measurements.getMedian());
				values.add(measurements.getUpperQuartile());
				values.add(measurements.getMin());
				values.add(measurements.getMax());
				
				return representSequence(new Tag("!!" + Measurements.class.getCanonicalName()), values, defaultFlowStyle);
			}
			
		}
	}

}
