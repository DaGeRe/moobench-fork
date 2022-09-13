package moobench.tools.results.data;

import java.util.ArrayList;
import java.util.List;

public class ValueTuple {

    private final long timestamp;

    List<Double> values = new ArrayList<>();

    public ValueTuple(final long timestamp) {
        this.timestamp = timestamp;
    }

    public long getTimestamp() {
        return this.timestamp;
    }

    public List<Double> getValues() {
        return this.values;
    }
}
