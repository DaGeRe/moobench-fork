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
public class CompileResultsMain extends AbstractService<TeetimeConfiguration, Settings> {

	 public static void main(final String[] args) {
		 final CompileResultsMain main = new CompileResultsMain();
		 System.exit(main.run("compile-result", "Compile Results", args, new Settings()));
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
		return true;
	}

	@Override
	protected void shutdownService() {
	}
}
