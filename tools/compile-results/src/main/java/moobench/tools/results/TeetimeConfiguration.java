package moobench.tools.results;

import java.io.File;
import java.io.FilenameFilter;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import moobench.tools.results.data.ExperimentLog;
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
        final JsonLogSink jsonLogSink = new JsonLogSink(settings.getJsonLogPath());
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
