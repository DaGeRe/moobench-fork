
package moobench.tools.results;

import java.nio.file.Path;
import java.util.List;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.converters.PathConverter;

public class Settings {
	
	@Parameter(names= { "-l", "--main-log" }, required = true, converter = PathConverter.class, description = "Main log file")
	private Path mainLogJson;

	@Parameter(names= { "-p", "--partial-log" }, required = true, converter = PathConverter.class, description = "Partial log file")
	private Path partialLogJson;
	
	@Parameter(names= { "-d", "--result-data" }, variableArity = true, required = true, converter = PathConverter.class, description = "Collection of experiment data")
	private List<Path> resultCsvPaths;
	
	@Parameter(names= { "-m", "--mapping-file" }, required = true, converter = PathConverter.class, description = "Experiment Result to log mapping")
	private Path mappingFile;
	
	@Parameter(names= { "-w", "--window" }, required = true, description = "Time Window Size")
	private Integer window;
	
	public Path getMainLogJson() {
		return mainLogJson;
	}
	
	public Path getPartialLogJson() {
		return partialLogJson;
	}
	
	public List<Path> getResultCsvPaths() {
		return resultCsvPaths;
	}
	
	public Path getMappingFile() {
		return mappingFile;
	}
	
	public Integer getWindow() {
		return window;
	}
}
