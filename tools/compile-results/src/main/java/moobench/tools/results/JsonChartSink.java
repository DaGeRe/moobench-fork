package moobench.tools.results;

import java.nio.file.Files;
import java.nio.file.Path;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import moobench.tools.results.data.Chart;
import moobench.tools.results.data.ValueTuple;
import teetime.framework.AbstractConsumerStage;

public class JsonChartSink extends AbstractConsumerStage<Chart> {

    private final Path path;

    public JsonChartSink(final Path path) {
        this.path = path;
    }

    @Override
    protected void execute(final Chart chart) throws Exception {
        final Path jsonLog = this.path.resolve(chart.getName() + "-partial.json");
        final ObjectMapper mapper = new ObjectMapper();

        final ObjectNode node = mapper.createObjectNode();
        final ArrayNode arrayNode = node.putArray("results");

        for(final ValueTuple value : chart.getValues()) {
            final ObjectNode objectNode = mapper.createObjectNode();
            for (int i = 0;i < chart.getHeaders().size();i++) {
                final String name = chart.getHeaders().get(i);
                final Double number = value.getValues().get(i);
                objectNode.put(name, number);
            }
            objectNode.put("time", value.getTimestamp());
            arrayNode.add(objectNode);
        }

        mapper.writeValue(Files.newBufferedWriter(jsonLog), node);
    }

}
