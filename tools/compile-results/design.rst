Compile Results
===============

Compile results reads in a set of YAML-files, appends them to longer YAML-logs,
creates a JSON-file over the last N builds and outputs a set of data to be
displayed in a HTML table.

Parameter
---------

-i input paths (multiple path)
-l log path (one path, the individual log paths will be computed from the input paths)
-w window length in number of builds
-t path for table
-j json output

Pipeline
--------

yamlInputPathsProducer ElementProducer(logFilePaths)
yamlInputReader YamlReaderStage()

logAppenderStage LogAppenderStage
distributor Distributor<>(CopyByReferenceStrategy())

yamlLogSink YamlLogSink(logPath)

chartAssemblerStage ChartAssemblerStage()
tailChartStage TailChartStage(windowSize)
jsonLogSink JsonChartSink(chartPath);

computeTableStage ComputeTableStage()
generateHtmlTableStage GenerateHtmlTableStage(tablePath)
fileSink FileSink()

yamlInputPathsProducer -> yamlInputReader -> logAppenderStage -> distributor

distributor -> yamlLogSink
distributor -> chartAssemblerStage -> tailChartStage -> jsonLogSink
distributor -> computeTableStage -> generateHtmlTableStage -> fileSink

Data Structure
--------------

**Log Model**

ExperimentLog:
- String kind
- List<Experiment> experiments

Experiment:
- long timestamp
- List<Measurements> measurements

Measurements:
- Double mean
- Double convidence
- Double standardDeviation
- Double lowerQuartile
- Double median
- Double upperQuartile
- Double max
- Double min

**Chart**

Chart:
- String name
- List<String> headers
- List<ValueTuple> values

ValueTuple:
- long timestamp
- List<Double> values

**Table**

TableInformation:
- String name
- Experiment current
- Experiment previous

In previous, we store an artifical results based on the last 10 experiments using
value = (experiment_i + value) / 2


