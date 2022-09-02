/***************************************************************************
 * Copyright (C) 2022 Kieker (https://kieker-monitoring.net)

 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ***************************************************************************/
package moobench.tools.results.data;

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
