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

import java.io.FileWriter;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import org.yaml.snakeyaml.DumperOptions;
import org.yaml.snakeyaml.Yaml;
import org.yaml.snakeyaml.nodes.Node;
import org.yaml.snakeyaml.nodes.Tag;
import org.yaml.snakeyaml.representer.Represent;
import org.yaml.snakeyaml.representer.Representer;

import moobench.tools.results.data.ExperimentLog;
import moobench.tools.results.data.Measurements;
import teetime.framework.AbstractConsumerStage;

public class YamlLogSink extends AbstractConsumerStage<ExperimentLog> {

    Path logPath;

    public YamlLogSink(final Path logPath) {
        this.logPath = logPath;
    }

    @Override
    protected void execute(final ExperimentLog log) throws Exception {
        final Path logPath = this.logPath.resolve(String.format("%s-log.yaml", log.getKind()));

        final Representer representer = new LogRepresenter();
        final DumperOptions options = new DumperOptions();
        final Yaml yaml = new Yaml(representer, options);

        final FileWriter writer = new FileWriter(logPath.toFile());
        yaml.dump(log, writer);
    }

    private class LogRepresenter extends Representer {

        public LogRepresenter() {
            this.representers.put(Measurements.class, new RepresentMeasurements());
        }

        private class RepresentMeasurements implements Represent {

            @Override
            public Node representData(final Object data) {
                final Measurements measurements = (Measurements)data;

                final List<Double> values = new ArrayList<>();
                values.add(measurements.getMean());
                values.add(measurements.getStandardDeviation());
                values.add(measurements.getConvidence());
                values.add(measurements.getLowerQuartile());
                values.add(measurements.getMedian());
                values.add(measurements.getUpperQuartile());
                values.add(measurements.getMin());
                values.add(measurements.getMax());

                return LogRepresenter.this.representSequence(new Tag("!!" + Measurements.class.getCanonicalName()), values, LogRepresenter.this.defaultFlowStyle);
            }

        }
    }

}
