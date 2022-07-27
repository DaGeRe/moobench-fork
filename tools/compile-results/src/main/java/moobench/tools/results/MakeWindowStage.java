package moobench.tools.results;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;

import teetime.stage.basic.AbstractFilter;

public class MakeWindowStage extends AbstractFilter<List<Map<String, JsonNode>>> {

	private Integer window;

	public MakeWindowStage(Integer window) {
		this.window = window;
	}

	@Override
	protected void execute(List<Map<String, JsonNode>> list) throws Exception {
		List<Map<String, JsonNode>> newList = new ArrayList<Map<String, JsonNode>>();
		for (int i=list.size()-window-1;i < list.size();i++) {
			newList.add(list.get(i));
		}
		this.outputPort.send(newList);
	}

}
