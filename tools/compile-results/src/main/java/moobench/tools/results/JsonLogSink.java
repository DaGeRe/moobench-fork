package moobench.tools.results;

import java.nio.file.Files;
import java.nio.file.Path;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import moobench.tools.results.data.Chart;
import moobench.tools.results.data.ValueTuple;
import teetime.framework.AbstractConsumerStage;

public class JsonLogSink extends AbstractConsumerStage<Chart> {

	private Path path;

	public JsonLogSink(Path path) {
		this.path = path;
	}

	@Override
	protected void execute(Chart chart) throws Exception {
		Path jsonLog = this.path.resolve(chart.getName() + ".json");
	    ObjectMapper mapper = new ObjectMapper();
	    
		ObjectNode node = mapper.createObjectNode();
		ArrayNode arrayNode = node.putArray("results");
		
		for(ValueTuple value : chart.getValues()) {
			ObjectNode objectNode = mapper.createObjectNode();
			for (int i = 0;i < chart.getHeaders().size();i++) {
				String name = chart.getHeaders().get(i);
				Double number = value.getValues().get(i);
				objectNode.put(name, number);
			}
			objectNode.put("time", value.getTimestamp());
			arrayNode.add(objectNode);
		}
		
		mapper.writeValue(Files.newBufferedWriter(jsonLog), node);
	}

}
