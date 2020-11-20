/**
 * 
 */
package moobench.benchmark;

import java.io.File;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.converters.FileConverter;

/**
 * @author Reiner Jung
 *
 */
public class BenchmarkParameter {
	
	@Parameter(names = { "--totalCalls", "-c" }, required = true, description = "Number of total method calls performed.")
	long totalCalls;
	
	@Parameter(names = { "--methodtime", "-m" }, required = true, description = "Time a method call takes.")
	long methodTime;
	
	@Parameter(names = { "--totalthreads", "-t" }, required = true, description = "Number of threads started.")
	long totalThreads;
			
	@Parameter(names = { "--recursiondepth", "-d" }, required = true, description = "Depth of recursion performed.")
	long recursionDepth;

	@Parameter(names = { "--output-filename", "-o" }, required = true, converter = FileConverter.class, 
			description = "Filename of results file. Output is appended if file exists.")
	File outputFile;
	
	@Parameter(names = { "--quickstart", "-q" }, required = false, description = "Skips initial garbage collection.")
	boolean quickstart;
	
	@Parameter(names = { "--forceTerminate", "-f" }, required = false, description = "Forces a termination at the end of the benchmark.")
	boolean forceTerminate;
    
	@Parameter(names = { "--runnable", "-r" }, required = false,
			description = "Class implementing the Runnable interface. run() method is executed before the benchmark starts.")
	String runnableClassname;
	
    @Parameter(names = { "--application", "-a" }, required = false, description = "Class implementing the MonitoredClass interface.")
    String applicationClassname;
    
    @Parameter(names = { "--benchmarkthread", "-b" }, required = false, description = "Class implementing the BenchmarkingThread interface.")
    String benchmarkClassname;

	public long getTotalCalls() {
		return totalCalls;
	}

	public long getMethodTime() {
		return methodTime;
	}

	public long getTotalThreads() {
		return totalThreads;
	}

	public long getRecursionDepth() {
		return recursionDepth;
	}

	public File getOutputFile() {
		return outputFile;
	}

	public boolean isQuickstart() {
		return quickstart;
	}

	public boolean isForceTerminate() {
		return forceTerminate;
	}

	public String getRunnableClassname() {
		return runnableClassname;
	}

	public String getApplicationClassname() {
		return applicationClassname;
	}

	public String getBenchmarkClassname() {
		return benchmarkClassname;
	}
    
    
    
}
