package moobench.tools.results;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.DoubleNode;

import teetime.framework.AbstractConsumerStage;
import teetime.framework.OutputPort;

public class ReadCsvFileSource extends AbstractConsumerStage<Path> {
	
	private final OutputPort<Map<String, JsonNode>> outputPort = this.createOutputPort();
	
	@Override
	protected void execute(Path path) throws Exception {
		final CSVParser csvParser = new CSVParser(Files.newBufferedReader(path), 
				CSVFormat.DEFAULT.withHeader());
		List<String> header = csvParser.getHeaderNames();
		Map<String, JsonNode> recordMap = new HashMap<>();
		CSVRecord record = csvParser.getRecords().get(0);
		for (int i=0;i<header.size();i++) {
			String value = record.get(header.get(i));
			recordMap.put(header.get(i).trim(), new DoubleNode(Double.parseDouble(value)));
		}
		csvParser.close();
		this.outputPort.send(recordMap);
	}

	public OutputPort<Map<String, JsonNode>> getOutputPort() {
		return this.outputPort;
	}
}
