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
import java.util.Map.Entry;

import moobench.tools.results.data.Experiment;
import moobench.tools.results.data.ExperimentLog;
import moobench.tools.results.data.Measurements;
import moobench.tools.results.data.TableInformation;
import teetime.stage.basic.AbstractTransformation;

/**
 * @author Reiner Jung
 * @since 1.3.0
 */
public class ComputeTableStage extends AbstractTransformation<ExperimentLog, TableInformation> {

    @Override
    protected void execute(final ExperimentLog log) throws Exception {
        final List<Experiment> experiments = log.getExperiments();
        if (experiments.size() > 0) {
            final Experiment current = experiments.get(experiments.size()-1);
            int first = experiments.size() - 10;
            int last = experiments.size() - 2;
            if (first < 0) {
                first = 0;
            }
            if (last < 0) {
                last = 0;
            }
            final Experiment previous = new Experiment();
            for (int i = first; i < last; i++) {
                final Experiment experiment = experiments.get(i);
                for (final Entry<String, Measurements> entry : experiment.getMeasurements().entrySet()) {
                    final Measurements measurements = entry.getValue();
                    if (!previous.getMeasurements().containsKey(entry.getKey())) {
                        previous.getMeasurements().put(entry.getKey(), measurements);
                    } else {
                        final Measurements previousMeasurements = previous.getMeasurements().get(entry.getKey());
                        previous.getMeasurements().put(entry.getKey(), this.computePrevious(previousMeasurements, measurements));
                    }
                }
            }

            this.outputPort.send(new TableInformation(log.getKind(), current, previous));
        }
    }

    private Measurements computePrevious(final Measurements previousMeasurements, final Measurements measurements) {
        return new Measurements(
                this.computeValue(measurements.getMean(), previousMeasurements.getMean()),
                this.computeValue(measurements.getStandardDeviation(), previousMeasurements.getStandardDeviation()),
                this.computeValue(measurements.getConvidence(), previousMeasurements.getConvidence()),
                this.computeValue(measurements.getLowerQuartile(), previousMeasurements.getLowerQuartile()),
                this.computeValue(measurements.getMedian(), previousMeasurements.getMedian()),
                this.computeValue(measurements.getUpperQuartile(), previousMeasurements.getUpperQuartile()),
                this.computeValue(measurements.getMin(), previousMeasurements.getMin()),
                this.computeValue(measurements.getMax(), previousMeasurements.getMax()));
    }

    private Double computeValue(final Double newValue, final Double previousValue) {
        if (newValue.isNaN() || newValue.isInfinite()) {
            return previousValue;
        } else if (previousValue.isNaN() || previousValue.isInfinite()) {
            return newValue;
        } else {
            return (newValue + previousValue)/2;
        }
    }

}
