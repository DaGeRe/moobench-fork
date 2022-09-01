package moobench.tools.results;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Set;

public class OrderedSet<T> extends ArrayList<T> implements Set<T> {

    private static final long serialVersionUID = 719655465496957772L;

    @Override
    public boolean add(final T value) {
        if (!super.contains(value)) {
            return super.add(value);
        } else {
            return false;
        }
    }

    @Override
    public boolean addAll(final Collection<? extends T> values) {
        boolean changed = false;
        for(final T value : values) {
            changed |= this.add(value);
        }
        return changed;
    }

}
