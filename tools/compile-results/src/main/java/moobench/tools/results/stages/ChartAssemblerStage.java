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
package moobench.tools.results.stages;

import java.util.List;
import java.util.Map;

import moobench.tools.results.data.Chart;
import moobench.tools.results.data.Experiment;
import moobench.tools.results.data.ExperimentLog;
import moobench.tools.results.data.Measurements;
import moobench.tools.results.data.ValueTuple;
import teetime.stage.basic.AbstractTransformation;

/**
 * @author Reiner Jung
 * @since 1.3.0
 *
 */
public class ChartAssemblerStage extends AbstractTransformation<ExperimentLog, Chart> {

    @Override
    protected void execute(final ExperimentLog element) throws Exception {
        final Chart chart = new Chart(element.getKind());
        for (final Experiment experiment : element.getExperiments()) {
            final long timestamp = Double.valueOf(experiment.getTimestamp()).longValue();
            final ValueTuple tuple = new ValueTuple(timestamp);

            this.addHeaderIfMissing(chart.getHeaders(), experiment.getMeasurements());
            this.fillInData(chart.getHeaders(), tuple.getValues(), experiment.getMeasurements());

            chart.getValues().add(tuple);
        }

        this.outputPort.send(chart);
    }

    private void fillInData(final List<String> headers, final List<Double> values, final Map<String, Measurements> measurements) {
        for (final String key : headers) {
            final Measurements value = measurements.get(key);
            if (value != null) {
                values.add(value.getMean());
            } else {
                values.add(Double.NaN);
            }
        }
    }

    private void addHeaderIfMissing(final List<String> headers, final Map<String, Measurements> measurements) {
        for (final String key : measurements.keySet()) {
            if (!headers.stream().anyMatch(header -> header.equals(key))) {
                headers.add(key);
            }
        }
    }

}
