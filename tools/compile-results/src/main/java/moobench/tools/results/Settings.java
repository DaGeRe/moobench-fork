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

import java.nio.file.Path;
import java.util.List;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.converters.PathConverter;

public class Settings {

    @Parameter(names = { "-i", "--input" }, variableArity = true, required = true, converter = PathConverter.class, description = "List of input data sets")
    private List<Path> inputPaths;

    @Parameter(names= { "-l", "--log" }, required = true, converter = PathConverter.class, description = "YAML log file root path")
    private Path logPath;

    @Parameter(names= { "-t", "--table" }, required = true, converter = PathConverter.class, description = "Output HTML table for results")
    private Path tablePath;

    @Parameter(names= { "-c", "--chart" }, required = true, converter = PathConverter.class, description = "Partial JSON log for charts")
    private Path jsonChartPath;

    @Parameter(names= { "-w", "--window" }, required = true, description = "Time Window Size")
    private Integer window;

    public List<Path> getInputPaths() {
        return this.inputPaths;
    }

    public Path getLogPath() {
        return this.logPath;
    }

    public Path getTablePath() {
        return this.tablePath;
    }

    public Path getJsonChartPath() {
        return this.jsonChartPath;
    }

    public Integer getWindow() {
        return this.window;
    }
}
