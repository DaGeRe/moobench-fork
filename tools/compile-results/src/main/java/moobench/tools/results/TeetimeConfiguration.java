package moobench.tools.results;

import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;

import teetime.framework.Configuration;
import teetime.stage.basic.distributor.Distributor;
import teetime.stage.basic.distributor.strategy.CopyByReferenceStrategy;

public class TeetimeConfiguration extends Configuration {

	public TeetimeConfiguration(Settings settings) {
		MainLogReader mainLogReader = new MainLogReader(settings.getMainLogJson());
		MappingFileReader mappingFileReader = new MappingFileReader(settings.getMappingFile());
		SpecialArrayElementStage arrayElementStage = new SpecialArrayElementStage(settings.getResultCsvPaths());
		ReadCsvFileSource readCsvFileSource = new ReadCsvFileSource();

		MergeDataStage mergeDataStage = new MergeDataStage();
		mergeDataStage.declareActive();

		Distributor<List<Map<String, JsonNode>>> distributor = new Distributor<>(new CopyByReferenceStrategy());

		LogWriter mainLogWriter = new LogWriter(settings.getMainLogJson());
		MakeWindowStage makeWindowStage = new MakeWindowStage(settings.getWindow());
		LogWriter partialLogWriter = new LogWriter(settings.getPartialLogJson());
		
		this.connectPorts(mainLogReader.getOutputPort(), mergeDataStage.getMainLogInputPort());
		this.connectPorts(mappingFileReader.getOutputPort(), mergeDataStage.getMappingInputPort());
		this.connectPorts(arrayElementStage.getOutputPort(), readCsvFileSource.getInputPort());
		this.connectPorts(readCsvFileSource.getOutputPort(), mergeDataStage.getNewDataInputPort());
		
		this.connectPorts(mergeDataStage.getOutputPort(), distributor.getInputPort());
		
		this.connectPorts(distributor.getNewOutputPort(), mainLogWriter.getInputPort());
		this.connectPorts(distributor.getNewOutputPort(), makeWindowStage.getInputPort());
		this.connectPorts(makeWindowStage.getOutputPort(), partialLogWriter.getInputPort());
	}
}
