/**
 * 
 */
package moobench.tools.compile.results;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.DoubleNode;
import com.fasterxml.jackson.databind.node.JsonNodeFactory;
import com.fasterxml.jackson.databind.node.LongNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Read the CSV output of the R script and the existing JSON file and append a
 * record to the JSON file based on the CSV dataset. Further compute a list of
 * the last 50 runs and the last relative values.
 *
 * @author Reiner Jung
 *
 */
public class CompileResultsMain {

	private static final String NO_INSTRUMENTATION = "No instrumentation";
	private static final String PARTIAL_RESULT_FILENAME = "partial-results.json";
	private static final String RELATIVE_RESULT_FILENAME = "relative-results.json";

	public static void main(String[] args) {
		try {
			final JsonNode rootNode;
			
			File jsonMainFile = Paths.get(args[1]).toFile();
			
			if (jsonMainFile.exists()) {
				/** Read JSON file. */
				rootNode = readJsonFile(jsonMainFile);
			} else {
				rootNode = readJsonString();
			}
			
			File jsonPartialFile = new File(jsonMainFile.getParentFile().getPath() + File.separator + PARTIAL_RESULT_FILENAME);
			File jsonRelativeFile = new File(jsonMainFile.getParentFile().getPath() + File.separator + RELATIVE_RESULT_FILENAME);

			JsonNode resultsNode = rootNode.get("results");
			
			if (!(resultsNode instanceof ArrayNode)) {
				System.exit(1);
			}
			
			ArrayNode arrayResultsNode = (ArrayNode)resultsNode;
			
			long build = cleanupInputData(arrayResultsNode);
			
			/** Read CSV file. */
			final CSVParser csvParser = new CSVParser(Files.newBufferedReader(Paths.get(args[0])), 
					CSVFormat.DEFAULT.withHeader());
			List<String> header = csvParser.getHeaderNames();
			
			JsonNodeFactory factory = JsonNodeFactory.instance;
			
			/** Put CSV data in main JSON. */
			for (CSVRecord record : csvParser.getRecords()) {
				Map<String, JsonNode> recordMap = new HashMap<>();
				recordMap.put("time",new LongNode(new Date().getTime()));
				recordMap.put("build",new LongNode(build++));
				for (int i=0; i < record.size(); i++) {
					recordMap.put(header.get(i).trim(), new DoubleNode(Double.parseDouble(record.get(i))));
				}
				arrayResultsNode.add(new ObjectNode(factory, recordMap));
			}
			
			/** Produce alternative outputs. */
			JsonNode partialRootNode = createPartialResultList(arrayResultsNode);
			JsonNode relativeRootNode = createRelativeResultList((ArrayNode)partialRootNode.get("results"));

			/** Write JSON files. */
			new ObjectMapper().writeValue(jsonMainFile, rootNode);
			new ObjectMapper().writeValue(jsonPartialFile, partialRootNode);		
			new ObjectMapper().writeValue(jsonRelativeFile, relativeRootNode);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Cleanup and build number computation.
	 * NOTE: This method has a side effect on the input data.
	 * 
	 * @param arrayResultsNode array node holding previous result data
	 * 
	 * @return returns the next build number and cleanups the labels in the input data
	 */
	private static long cleanupInputData(ArrayNode arrayResultsNode) {
		long build = 0;
		/** Cleanup input data if necessary and determine highest build number. */
		for (int i=0;i<arrayResultsNode.size();i++) {
			JsonNode node = arrayResultsNode.get(i);
			if (node instanceof ObjectNode) {
				ObjectNode objectNode = (ObjectNode)node;
				
				Iterator<Entry<String, JsonNode>> iterator = objectNode.fields();
				while (iterator.hasNext()) {
					Entry<String, JsonNode> entry = iterator.next();
					objectNode.remove(entry.getKey());
					objectNode.set(entry.getKey().trim(), entry.getValue());
				}
				
				JsonNode buildValue = objectNode.get("build");
				if (buildValue != null) {
					if (build <= buildValue.asLong()) {
						build = buildValue.asLong() + 1;
					}
				}
			}
		}
		
		return build;
	}

	private static JsonNode createRelativeResultList(ArrayNode arrayNode) {
		JsonNodeFactory factory = JsonNodeFactory.instance;
		ArrayNode relativeResultsNode = new ArrayNode(factory);
		
		for (int i=0; i < arrayNode.size(); i++) {
			JsonNode element = arrayNode.get(i);
			Map<String, JsonNode> valueMap = new HashMap<>();
			
			Double baseline = ((DoubleNode)element.get(NO_INSTRUMENTATION)).asDouble();
						
			Iterator<Entry<String, JsonNode>> elementValueIterator = element.fields();
			while (elementValueIterator.hasNext()) {
				Entry<String, JsonNode> value = elementValueIterator.next();
				valueMap.put(value.getKey(), new DoubleNode((value.getValue().asDouble()-baseline)/baseline));
			}
		}

		Map<String, JsonNode> map = new HashMap<>();
		map.put("results", relativeResultsNode);

		return new ObjectNode(factory, map);
	}

	private static JsonNode createPartialResultList(ArrayNode arrayNode) {
		JsonNodeFactory factory = JsonNodeFactory.instance;

		ArrayNode partialResultsNode = new ArrayNode(factory);

		for (int i=0; i < arrayNode.size(); i++) {
			JsonNode element = arrayNode.get(i);
			Map<String, JsonNode> valueMap = new HashMap<>();
			Iterator<Entry<String, JsonNode>> elementValueIterator = element.fields();
			while (elementValueIterator.hasNext()) {
				Entry<String, JsonNode> value = elementValueIterator.next();
				valueMap.put(value.getKey(), value.getValue());
			}
		}
		
		Map<String, JsonNode> map = new HashMap<>();
		map.put("results", partialResultsNode);

		return new ObjectNode(factory, map);
	}

	private static JsonNode readJsonString() throws JsonMappingException, JsonProcessingException {
		ObjectMapper mapper = new ObjectMapper();
		String value = "{ \"results\" : [] }";
		return mapper.readTree(value);
	}

	private static JsonNode readJsonFile(File file) throws JsonProcessingException, IOException {
		ObjectMapper mapper = new ObjectMapper();
		return mapper.readTree(file);
	}
}
