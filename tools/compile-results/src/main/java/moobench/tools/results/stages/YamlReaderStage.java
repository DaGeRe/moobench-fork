package moobench.tools.results.stages;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.constructor.Constructor;

import moobench.tools.results.data.ExperimentLog;
import teetime.stage.basic.AbstractTransformation;

public class YamlReaderStage extends AbstractTransformation<Path, ExperimentLog> {

	@Override
	protected void execute(Path path) throws Exception {
		if (Files.exists(path)) {
			Yaml yaml = new Yaml(new Constructor(ExperimentLog.class));
			InputStream inputStream = Files.newInputStream(path);
			ExperimentLog data = yaml.load(inputStream);
			
			this.outputPort.send(data);
		} else
			this.logger.error("Cannot read YAML log file {}", path.toString());
	}

}
