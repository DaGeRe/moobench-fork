package moobench.tools.results;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import teetime.framework.AbstractConsumerStage;

public class LogWriter extends AbstractConsumerStage<List<Map<String,JsonNode>>> {
	
	private Path logJson;

	public LogWriter(Path logJson) {
		this.logJson = logJson;
	}

	@Override
	protected void execute(List<Map<String,JsonNode>> list) throws Exception {
		ObjectMapper mapper = new ObjectMapper();
		ObjectNode node = mapper.createObjectNode();
		ArrayNode arrayNode = node.putArray("results");
		
		for(Map<String, JsonNode> map : list) {
			ObjectNode objectNode = mapper.createObjectNode();
			for (Entry<String, JsonNode> entry : map.entrySet()) {
				JsonNode value = entry.getValue();
				if (value.isDouble())
					objectNode.put(entry.getKey(), value.asDouble());
				else if (value.isInt())
					objectNode.put(entry.getKey(), value.asInt());
				else
					this.logger.warn("property {} is of type {}", entry.getKey(), value.getNodeType().toString());
			}
			arrayNode.add(objectNode);
		}
		
		mapper.writeValue(Files.newBufferedWriter(logJson), node);
	}

}
