/**
 *
 */
package moobench.tools.results;

import java.util.List;
import java.util.Map.Entry;

import moobench.tools.results.data.Experiment;
import moobench.tools.results.data.ExperimentLog;
import moobench.tools.results.data.Measurements;
import moobench.tools.results.data.TableInformation;
import teetime.stage.basic.AbstractTransformation;

/**
 * @author reiner
 *
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
        return new Measurements((measurements.getMean() + previousMeasurements.getMean())/2,
                (measurements.getStandardDeviation() + previousMeasurements.getStandardDeviation())/2,
                (measurements.getConvidence() + previousMeasurements.getConvidence())/2,
                (measurements.getLowerQuartile() + previousMeasurements.getLowerQuartile())/2,
                (measurements.getMedian() + previousMeasurements.getMedian())/2,
                (measurements.getUpperQuartile() + previousMeasurements.getUpperQuartile())/2,
                (measurements.getMin() + previousMeasurements.getMin())/2,
                (measurements.getMax() + previousMeasurements.getMax())/2);
    }

}
