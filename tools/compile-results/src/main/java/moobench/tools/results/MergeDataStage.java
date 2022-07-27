package moobench.tools.results;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import teetime.framework.AbstractStage;
import teetime.framework.InputPort;
import teetime.framework.OutputPort;

public class MergeDataStage extends AbstractStage {
	
	private static final String BUILD_LABEL = "build";

	private final InputPort<Map<String, String>> mappingInputPort = this.createInputPort();
	private final InputPort<List<Map<String, JsonNode>>> mainLogInputPort = this.createInputPort();
	private final InputPort<Map<String, JsonNode>> newDataInputPort = this.createInputPort();

	private final OutputPort<List<Map<String, JsonNode>>> outputPort = this.createOutputPort();
	
	private List<Map<String, JsonNode>> mainLog;
	private List<Map<String, JsonNode>> bufferLog = new ArrayList<>();
	private Map<String, String> mapping;

	
	@Override
	protected void execute() throws Exception {
		List<Map<String, JsonNode>> log = this.mainLogInputPort.receive();
		if (log != null) {
			mainLog = log;
		}
		Map<String, String> newMapping = this.mappingInputPort.receive();
		if (newMapping != null) {
			mapping = newMapping;
		}
		Map<String, JsonNode> newData = this.newDataInputPort.receive();
		if (newData != null) {
			bufferLog.add(newData);
		}
	}
		
	@Override
	protected void onTerminating() {
		moveNewData();
		this.outputPort.send(mainLog);
		super.onTerminating();
	}
	
	private void moveNewData() {
		int last = mainLog.size()-1;
		int build = mainLog.get(last).get(BUILD_LABEL).asInt() + 1;
		
		Map<String,JsonNode> node = new HashMap<>();
		node.put(BUILD_LABEL, new ObjectMapper().getNodeFactory().numberNode(build));
		
		for (Map<String, JsonNode> data : bufferLog) {
			for (Entry<String, JsonNode> entry : data.entrySet()) {
				node.put(entry.getKey(), entry.getValue());
			}
		}
		bufferLog.clear();
		mainLog.add(node);
	}


	public InputPort<List<Map<String, JsonNode>>> getMainLogInputPort() {
		return this.mainLogInputPort;
	}

	public InputPort<Map<String,String>> getMappingInputPort() {
		return this.mappingInputPort;
	}

	public InputPort<Map<String,JsonNode>> getNewDataInputPort() {
		return this.newDataInputPort ;
	}

	public OutputPort<List<Map<String, JsonNode>>> getOutputPort() {
		return this.outputPort;
	}

}
