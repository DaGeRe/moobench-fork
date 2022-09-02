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

import java.util.HashMap;
import java.util.Map;

/**
 * @author Reiner Jung
 *
 */
public class Experiment {

    double timestamp;
    Map<String,Measurements> measurements = new HashMap<>();

    public double getTimestamp() {
        return this.timestamp;
    }

    public void setTimestamp(final double timestamp) {
        this.timestamp = timestamp;
    }

    public Map<String,Measurements> getMeasurements() {
        return this.measurements;
    }
    public void setMeasurements(final Map<String,Measurements> measurements) {
        this.measurements = measurements;
    }

    @Override
    public String toString() {
        return String.format("time: %f, measurements: %d\n", this.timestamp, this.measurements.size());
    }

}
