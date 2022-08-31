package moobench.tools.results;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;

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

		LogAppender :: logAppender
		Distributor :: distributor

		YamlLogSink :: yamlLogSink
		ChartAssemblerStage :: chartAssemblerStage
		JsonLogSink :: jsonLogSink
		GenerateHtmlTable :: generateHtmlTable
		FileSink :: fileSink

		yamlInputPathsProducer -> logAppender.newRecord
		yamlLogPathsProducer -> logAppender.log

		logAppender.output -- log -> distributor
		distributor -> yamlLogSink
		distributor -> chartAssemblerStage -> jsonLogSink
		distributor -> generateHtmlTable -> fileSink
	}
}
