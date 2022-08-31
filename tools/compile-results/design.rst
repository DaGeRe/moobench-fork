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

Log Paths
---------

log_file_path = log path + "/all-" + basename(input path)

Pipeline
--------

ElementProducer :: yamlInputPathsProducer
ElementProducer :: yamlLogPathsProducer

YamlReaderStage :: yamlInputReaderStage
YamlReaderStage :: yamlLogReaderStage

LogAppender :: logAppender
Distributor :: distributor

YamlLogSink :: yamlLogSink
ChartAssemblerStage :: chartAssemblerStage
JsonLogSink :: jsonLogSink
GenerateHtmlTable :: generateHtmlTable
FileSink :: fileSink

yamlInputPathsProducer -> yamlInputReaderStage -> logAppender.newRecord
yamlLogPathsProducer -> yamlLogReaderStage -> logAppender.log

logAppender.output -- log -> distributor
distributor -> yamlLogSink
distributor -> chartAssemblerStage -> jsonLogSink
distributor -> generateHtmlTable -> fileSink

Data Structure
--------------

Log
- string name
- List<Entry> entries

Entry
- long timestamp
- Map<String, List<Double>>

