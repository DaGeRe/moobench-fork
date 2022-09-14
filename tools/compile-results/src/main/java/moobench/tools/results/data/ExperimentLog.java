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
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class ExperimentLog {

    String kind;
    List<Experiment> experiments = new ArrayList<>();

    public String getKind() {
        return this.kind;
    }

    public void setKind(final String kind) {
        this.kind = kind;
    }

    public List<Experiment> getExperiments() {
        return this.experiments;
    }

    public void setExperiments(final List<Experiment> experiments) {
        this.experiments = experiments;
    }

    public void sort() {
	    Collections.sort(this.experiments, new Comparator<Experiment>() {
	
	        @Override
	        public int compare(final Experiment left, final Experiment right) {
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
