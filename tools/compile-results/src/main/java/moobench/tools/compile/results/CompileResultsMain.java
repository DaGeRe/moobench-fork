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
import java.util.List;
import java.util.Map;

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
 * record to the JSON file based on the CSV dataset.
 *
 * @author Reiner Jung
 *
 */
public class CompileResultsMain {

	public static void main(String[] args) {
		try {
			final JsonNode rootNode;
			if (Paths.get(args[1]).toFile().exists()) {
				/** Read JSON file. */
				rootNode = readJsonFile(Paths.get(args[1]).toFile());
			} else {
				rootNode = readJsonString();
			}
			
			JsonNode resultsNode = rootNode.get("results");
			
			if (!(resultsNode instanceof ArrayNode)) {
				System.exit(1);
			}
			
			ArrayNode arrayResultsNode = (ArrayNode)resultsNode;
			
			long build = arrayResultsNode.size();
			
			/** Fix old data in necessary. */
			for (int i=0;i<arrayResultsNode.size();i++) {
				JsonNode node = arrayResultsNode.get(i);
				if (node instanceof ObjectNode) {
					ObjectNode objectNode = (ObjectNode)node;
					JsonNode timeValue = objectNode.get("time");
					if (timeValue == null) {
						objectNode.put("time", new Date().getTime());
					}
					JsonNode buildValue = objectNode.get("build");
					if (buildValue == null) {
						objectNode.put("build", i);
					}
				}
			}
			
			/** Read CSV file. */
			final CSVParser csvParser = new CSVParser(Files.newBufferedReader(Paths.get(args[0])), 
					CSVFormat.DEFAULT.withHeader());
			List<String> header = csvParser.getHeaderNames();
			
			JsonNodeFactory factory = JsonNodeFactory.instance;
			
			/** Put CSV in JSON. */
			for (CSVRecord record : csvParser.getRecords()) {
				Map<String, JsonNode> recordMap = new HashMap<>();
				recordMap.put("time",new LongNode(new Date().getTime()));
				recordMap.put("build",new LongNode(build++));
				for (int i=0; i < record.size(); i++) {
					recordMap.put(header.get(i), new DoubleNode(Double.parseDouble(record.get(i))));
				}
				arrayResultsNode.add(new ObjectNode(factory, recordMap));
			}
			
			/** Check consistency. */
			

			/** Write JSON file. */
			ObjectMapper mapper = new ObjectMapper();
			mapper.writeValue(Paths.get(args[1]).toFile(), rootNode);
		} catch (IOException e) {
			e.printStackTrace();
		}
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
