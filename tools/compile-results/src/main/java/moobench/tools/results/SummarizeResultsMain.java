/**
 * 
 */
package moobench.tools.results;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;

import com.beust.jcommander.JCommander;

import kieker.common.configuration.Configuration;
import kieker.common.exception.ConfigurationException;
import kieker.tools.common.AbstractService;

/**
 * Read the CSV output of the R script and the existing JSON file and append a
 * record to the JSON file based on the CSV dataset. Further compute a list of
 * the last 50 runs and the last relative values.
 *
 * @author Reiner Jung
 *
 */
public class SummarizeResultsMain extends AbstractService<TeetimeConfiguration, Settings> {

	 public static void main(final String[] args) {
		 final SummarizeResultsMain main = new SummarizeResultsMain();
		 System.exit(main.run("summarize-result", "Summarize Results", args, new Settings()));
	 }
	
	@Override
	protected TeetimeConfiguration createTeetimeConfiguration() throws ConfigurationException {
		return new TeetimeConfiguration(this.parameterConfiguration);
	}

	@Override
	protected File getConfigurationFile() {
		return null;
	}

	@Override
	protected boolean checkConfiguration(Configuration configuration, JCommander commander) {
		return true;
	}

	@Override
	protected boolean checkParameters(JCommander commander) throws ConfigurationException {
		if (!Files.exists(this.parameterConfiguration.getMainLogJson().getParent())) {
			this.logger.error("Main log does not exist {}", this.parameterConfiguration.getMainLogJson().toString());
			return false;
		} else if (!Files.exists(this.parameterConfiguration.getMainLogJson())) {
			this.logger.info("Main log file does not exist, creating one {}", this.parameterConfiguration.getMainLogJson().toString());
		}
		if (!Files.isDirectory(this.parameterConfiguration.getPartialLogJson().getParent())) {
			this.logger.error("Partial log directory does not exist {}", this.parameterConfiguration.getPartialLogJson().getParent().toString());
			return false;
		}
		for (Path path : parameterConfiguration.getResultCsvPaths()) {
			if (!Files.exists(this.parameterConfiguration.getMainLogJson())) {
				this.logger.error("Experiment data file does not exist {}", path.toString());
				return false;
			}
		}
		if (!Files.exists(this.parameterConfiguration.getMappingFile())) {
			this.logger.error("Mapping file does not exist {}", this.parameterConfiguration.getMappingFile().toString());
			return false;
		}
		return true;
	}

	@Override
	protected void shutdownService() {
	}
}
