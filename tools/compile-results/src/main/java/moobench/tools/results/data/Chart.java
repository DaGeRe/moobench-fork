package moobench.tools.results.data;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class Chart {

    final String name;
    final List<String> headers = new ArrayList<>();
    final List<ValueTuple> values = new ArrayList<ValueTuple>();

    public Chart(final String name) {
        this.name = name;
    }

    public String getName() {
        return this.name;
    }

    public List<String> getHeaders() {
        return this.headers;
    }

    public List<ValueTuple> getValues() {
        return this.values;
    }

    public void sort() {
        Collections.sort(this.values, new Comparator<ValueTuple>() {

            @Override
            public int compare(final ValueTuple left, final ValueTuple right) {
                if (left.getTimestamp() < right.getTimestamp()) {
                    return -1;
                } else if (left.getTimestamp() > right.getTimestamp()) {
                    return 1;
                } else {
                    return 0;
                }
            }
        });
    }
}
