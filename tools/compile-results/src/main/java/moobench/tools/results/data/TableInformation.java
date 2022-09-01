package moobench.tools.results.data;

public class TableInformation {

    private final String name;

    private final Experiment current;
    private final Experiment previous;

    public TableInformation(final String name, final Experiment current, final Experiment previous) {
        this.name = name;
        this.current = current;
        this.previous = previous;
    }

    public String getName() {
        return this.name;
    }

    public Experiment getCurrent() {
        return this.current;
    }

    public Experiment getPrevious() {
        return this.previous;
    }
}
