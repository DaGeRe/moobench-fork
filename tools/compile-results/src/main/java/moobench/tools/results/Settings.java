
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
	
	@Parameter(names= { "-j", "--json-log" }, required = true, converter = PathConverter.class, description = "Partial JSON log for viewing")
	private Path jsonLogPath;
	
	@Parameter(names= { "-w", "--window" }, required = true, description = "Time Window Size")
	private Integer window;

	public List<Path> getInputPaths() {
		return inputPaths;
	}
	
	public Path getLogPath() {
		return logPath;
	}
	
	public Path getTablePath() {
		return tablePath;
	}
	
	public Path getJsonLogPath() {
		return jsonLogPath;
	}
	
	public Integer getWindow() {
		return window;
	}
}
