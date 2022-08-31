package moobench.tools.results;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;

import moobench.tools.results.data.ExperimentLog;
import teetime.framework.Configuration;
import teetime.stage.basic.distributor.Distributor;
import teetime.stage.basic.distributor.strategy.CopyByReferenceStrategy;

public class TeetimeConfiguration extends Configuration {

	public TeetimeConfiguration(Settings settings) {
		List<Path> logFilePaths = new ArrayList<Path>();
		for (Path path : settings.getInputPaths()) {
			logFilePaths.add(settings.getLogPath().resolve(path.getFileName()));
		}
			
		ElementProducer<Path> yamlInputPathsProducer = new ElementProducer<>(settings.getInputPaths());
		ElementProducer<Path> yamlLogPathsProducer = new ElementProducer<>(logFilePaths);
		
		YamlReaderStage yamlInputReader = new YamlReaderStage();
		YamlReaderStage yamlLogReader = new YamlReaderStage();

		LogAppenderStage logAppenderStage = new LogAppenderStage();
		Distributor<ExperimentLog> distributor = new Distributor<>(new CopyByReferenceStrategy());

		YamlLogSink yamlLogSink = new YamlLogSink();
		
		//ChartAssemblerStage :: chartAssemblerStage
		//JsonLogSink :: jsonLogSink
		//GenerateHtmlTable :: generateHtmlTable
		//FileSink :: fileSink

		this.connectPorts(yamlInputPathsProducer.getOutputPort(), yamlInputReader.getInputPort());
		this.connectPorts(yamlLogPathsProducer.getOutputPort(), yamlLogReader.getInputPort());
		
		this.connectPorts(yamlInputReader.getOutputPort(), logAppenderStage.getNewDataInputPort());
		this.connectPorts(yamlLogReader.getOutputPort(), logAppenderStage.getLogInputPort());
		
		this.connectPorts(logAppenderStage.getOutputPort(), distributor.getInputPort());
		
		this.connectPorts(distributor.getNewOutputPort(), yamlLogSink.getInputPort());
	}
}
