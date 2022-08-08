/**
 * 
 */
package moobench.tools.results;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import teetime.framework.AbstractProducerStage;

/**
 * @author reiner
 *
 */
public class MainLogReader extends AbstractProducerStage<List<Map<String,JsonNode>>> {
	
	private static final String RESULTS_LABEL = "results";

	private final Path mainLogJson;

	public MainLogReader(Path mainLogJson) {
		this.mainLogJson = mainLogJson;
	}

	@Override
	protected void execute() throws JsonProcessingException, IOException {
		List<Map<String,JsonNode>> result = new ArrayList<Map<String,JsonNode>>();
		JsonNode node;
		if (Files.exists(mainLogJson)) {
			node = readJsonFile();
		} else {
			node = readJsonString();
		}
		
		JsonNode resultsNode = node.get(RESULTS_LABEL);
		if ((resultsNode instanceof ArrayNode)) {
			ArrayNode arrayNode = (ArrayNode)resultsNode;
			Iterator<JsonNode> iterator = arrayNode.elements();
			while (iterator.hasNext()) {
				JsonNode element = iterator.next();
				if (element instanceof ObjectNode) {
					ObjectNode objectNode = (ObjectNode)element;
										
					Iterator<Entry<String, JsonNode>> elementIterator = objectNode.fields();
					Map<String,JsonNode> row = new HashMap<>();
					while (elementIterator.hasNext()) {
						Entry<String, JsonNode> parameter = elementIterator.next();
						row.put(parameter.getKey(), parameter.getValue());
					}
					result.add(row);
				}
			}
		}
		
		this.outputPort.send(result);
		this.workCompleted();
	}
	

	
	private JsonNode readJsonString() throws JsonMappingException, JsonProcessingException {
		ObjectMapper mapper = new ObjectMapper();
		String value = "{ \"results\" : [] }";
		return mapper.readTree(value);
	}

	private JsonNode readJsonFile() throws JsonProcessingException, IOException {
		ObjectMapper mapper = new ObjectMapper();
		return mapper.readTree(Files.newInputStream(mainLogJson));
	}

}
