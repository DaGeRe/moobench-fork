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
package moobench.tools.results;

import java.io.File;
import java.io.FilenameFilter;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import moobench.tools.results.data.ExperimentLog;
import moobench.tools.results.stages.ChartAssemblerStage;
import moobench.tools.results.stages.ComputeTableStage;
import moobench.tools.results.stages.ElementProducer;
import moobench.tools.results.stages.FileSink;
import moobench.tools.results.stages.GenerateHtmlTableStage;
import moobench.tools.results.stages.JsonChartSink;
import moobench.tools.results.stages.LogAppenderStage;
import moobench.tools.results.stages.TailChartStage;
import moobench.tools.results.stages.YamlLogSink;
import moobench.tools.results.stages.YamlReaderStage;
import teetime.framework.Configuration;
import teetime.stage.basic.distributor.Distributor;
import teetime.stage.basic.distributor.strategy.CopyByReferenceStrategy;

public class TeetimeConfiguration extends Configuration {

    public TeetimeConfiguration(final Settings settings) {
        final List<Path> logFilePaths = this.createInputPaths(settings);

        final ElementProducer<Path> yamlInputPathsProducer = new ElementProducer<>(logFilePaths);

        final YamlReaderStage yamlInputReader = new YamlReaderStage();

        final LogAppenderStage logAppenderStage = new LogAppenderStage();
        final Distributor<ExperimentLog> distributor = new Distributor<>(new CopyByReferenceStrategy());

        final YamlLogSink yamlLogSink = new YamlLogSink(settings.getLogPath());

        final ChartAssemblerStage chartAssemblerStage = new ChartAssemblerStage();
        final TailChartStage tailChartStage = new TailChartStage(settings.getWindow());
        final JsonChartSink jsonLogSink = new JsonChartSink(settings.getJsonChartPath());

        final ComputeTableStage computeTableStage = new ComputeTableStage();
        final GenerateHtmlTableStage generateHtmlTableStage = new GenerateHtmlTableStage(settings.getTablePath());
        final FileSink fileSink = new FileSink();

        this.connectPorts(yamlInputPathsProducer.getOutputPort(), yamlInputReader.getInputPort());
        this.connectPorts(yamlInputReader.getOutputPort(), logAppenderStage.getInputPort());

        this.connectPorts(logAppenderStage.getOutputPort(), distributor.getInputPort());

        this.connectPorts(distributor.getNewOutputPort(), yamlLogSink.getInputPort());
        this.connectPorts(distributor.getNewOutputPort(), chartAssemblerStage.getInputPort());
        this.connectPorts(distributor.getNewOutputPort(), computeTableStage.getInputPort());

        this.connectPorts(computeTableStage.getOutputPort(), generateHtmlTableStage.getInputPort());
        this.connectPorts(generateHtmlTableStage.getOutputPort(), fileSink.getInputPort());

        this.connectPorts(chartAssemblerStage.getOutputPort(), tailChartStage.getInputPort());
        this.connectPorts(tailChartStage.getOutputPort(), jsonLogSink.getInputPort());
    }

    private List<Path> createInputPaths(final Settings settings) {
        final ArrayList<Path> logFilePaths = new ArrayList<Path>();
        for (final Path path : settings.getInputPaths()) {
            logFilePaths.add(path);
        }
        final FilenameFilter filter = new FilenameFilter() {

            @Override
            public boolean accept(final File file, final String name) {
                final int last = name.lastIndexOf(".");
                if (last < 0) {
                    return false;
                }
                final String extension = name.substring(last+1);
                return "yaml".equals(extension);
            }
        };
        for (final File file : settings.getLogPath().toFile().listFiles(filter)) {
            logFilePaths.add(file.toPath());
        }

        return logFilePaths;
    }
}
