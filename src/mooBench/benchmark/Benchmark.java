/***************************************************************************
 * Copyright 2014 Kieker Project (http://kieker-monitoring.net)
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

package mooBench.benchmark;

import java.io.BufferedOutputStream;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.OptionBuilder;
import org.apache.commons.cli.Options;

import mooBench.monitoredApplication.MonitoredClass;
import mooBench.monitoredApplication.MonitoredClassThreaded;

/**
 * @author Jan Waller
 */
public final class Benchmark {
	private static final String ENCODING = "UTF-8";

	private static PrintStream ps = null;
	private static String outputFn = null;
	private static int totalThreads = 0;
	private static int totalCalls = 0;
	private static long methodTime = 0;
	private static int recursionDepth = 0;
	private static boolean quickstart = false;
	private static MonitoredClass mc = null;

	private Benchmark() {}

	public static void main(final String[] args) throws InterruptedException {

		// 1. Preparations
		Benchmark.parseAndInitializeArguments(args);

		System.out.println(" # Experiment run configuration:"); // NOPMD (System.out)
		System.out.println(" # 1. Output filename " + Benchmark.outputFn); // NOPMD (System.out)
		System.out.println(" # 2. Recursion Depth " + Benchmark.recursionDepth); // NOPMD (System.out)
		System.out.println(" # 3. Threads " + Benchmark.totalThreads); // NOPMD (System.out)
		System.out.println(" # 4. Total-Calls " + Benchmark.totalCalls); // NOPMD (System.out)
		System.out.println(" # 5. Method-Time " + Benchmark.methodTime); // NOPMD (System.out)

		// 2. Initialize Threads and Classes
		final CountDownLatch doneSignal = new CountDownLatch(Benchmark.totalThreads);
		final BenchmarkingThread[] benchmarkingThreads = new BenchmarkingThread[Benchmark.totalThreads];
		final Thread[] threads = new Thread[Benchmark.totalThreads];
		for (int i = 0; i < Benchmark.totalThreads; i++) {
			benchmarkingThreads[i] = new BenchmarkingThreadNano(Benchmark.mc, Benchmark.totalCalls, Benchmark.methodTime, Benchmark.recursionDepth, doneSignal);
			threads[i] = new Thread(benchmarkingThreads[i], String.valueOf(i + 1));
		}
		if (!quickstart) {
			for (int l = 0; l < 4; l++) {
				{ // NOCS (reserve mem only within the block)
					final long freeMemChunks = Runtime.getRuntime().freeMemory() >> 27;
					// System.out.println("Free-Mem: " + Runtime.getRuntime().freeMemory());
					final int memSize = 128 * 1024 * 128; // memSize * 8 = total Bytes -> 128MB
					for (int j = 0; j < freeMemChunks; j++) {
						final long[] grabMemory = new long[memSize];
						for (int i = 0; i < memSize; i++) {
							grabMemory[i] = System.nanoTime();
						}
					}
					// System.out.println("done grabbing memory...");
					// System.out.println("Free-Mem: " + Runtime.getRuntime().freeMemory());
				}
				Thread.sleep(5000);
			}
		}
		final long startTime = System.currentTimeMillis();
		System.out.println(" # 6. Starting benchmark ..."); // NOPMD (System.out)
		// 3. Starting Threads
		for (int i = 0; i < Benchmark.totalThreads; i++) {
			threads[i].start();
		}

		// 4. Wait for all Threads
		try {
			doneSignal.await();
		} catch (final InterruptedException e) {
			e.printStackTrace(); // NOPMD (Stacktrace)
			System.exit(-1);
		}
		final long totalTime = System.currentTimeMillis() - startTime;
		System.out.println(" #    done (" + TimeUnit.MILLISECONDS.toSeconds(totalTime) + " s)"); // NOPMD (System.out)

		// 5. Print experiment statistics
		System.out.print(" # 7. Writing results ... "); // NOPMD (System.out)
		// CSV Format: configuration;order_index;Thread-ID;duration_nsec
		long[] timings;
		for (int h = 0; h < Benchmark.totalThreads; h++) {
			timings = benchmarkingThreads[h].getTimings();
			for (int i = 0; i < Benchmark.totalCalls; i++) {
				Benchmark.ps.println(threads[h].getName() + ";" + timings[i]);
			}
		}
		Benchmark.ps.close();

		System.out.println("done"); // NOPMD (System.out)
		System.out.println(" # "); // NOPMD (System.out)

		// System.exit(0);
	}

	@SuppressWarnings("static-access")
	public static void parseAndInitializeArguments(final String[] args) {
		final Options cmdlOpts = new Options();
		cmdlOpts.addOption(OptionBuilder.withLongOpt("totalcalls").withArgName("calls").hasArg(true).isRequired(true)
				.withDescription("Number of total method calls performed.").withValueSeparator('=').create("t"));
		cmdlOpts.addOption(OptionBuilder.withLongOpt("methodtime").withArgName("time").hasArg(true).isRequired(true).withDescription("Time a method call takes.")
				.withValueSeparator('=').create("m"));
		cmdlOpts.addOption(OptionBuilder.withLongOpt("totalthreads").withArgName("threads").hasArg(true).isRequired(true)
				.withDescription("Number of threads started.").withValueSeparator('=').create("h"));
		cmdlOpts.addOption(OptionBuilder.withLongOpt("recursiondepth").withArgName("depth").hasArg(true).isRequired(true)
				.withDescription("Depth of recursion performed.").withValueSeparator('=').create("d"));
		cmdlOpts.addOption(OptionBuilder.withLongOpt("output-filename").withArgName("filename").hasArg(true).isRequired(true)
				.withDescription("Filename of results file. Output is appended if file exists.").withValueSeparator('=').create("o"));
		cmdlOpts.addOption(OptionBuilder.withLongOpt("quickstart").isRequired(false).withDescription("Skips initial garbage collection.").create("q"));
		cmdlOpts.addOption(OptionBuilder.withLongOpt("runnable").withArgName("classname").hasArg(true).isRequired(false)
				.withDescription("Class implementing the Runnable interface. run() method is executed before the benchmark starts.").withValueSeparator('=')
				.create("r"));
		cmdlOpts.addOption(OptionBuilder.withLongOpt("application").withArgName("classname").hasArg(true).isRequired(false)
				.withDescription("Class implementing the MonitoredClass interface.").withValueSeparator('=')
				.create("a"));
		cmdlOpts.addOption(OptionBuilder.withLongOpt("benchmarkthread").withArgName("classname").hasArg(true).isRequired(false)
				.withDescription("Class implementing the BenchmarkingThread interface.").withValueSeparator('=')
				.create("b"));
		try {
			CommandLine cmdl = null;
			final CommandLineParser cmdlParser = new BasicParser();
			cmdl = cmdlParser.parse(cmdlOpts, args);
			Benchmark.outputFn = cmdl.getOptionValue("output-filename");
			Benchmark.totalCalls = Integer.parseInt(cmdl.getOptionValue("totalcalls"));
			Benchmark.methodTime = Integer.parseInt(cmdl.getOptionValue("methodtime"));
			Benchmark.totalThreads = Integer.parseInt(cmdl.getOptionValue("totalthreads"));
			Benchmark.recursionDepth = Integer.parseInt(cmdl.getOptionValue("recursiondepth"));
			Benchmark.quickstart = cmdl.hasOption("quickstart");
			Benchmark.ps = new PrintStream(new BufferedOutputStream(new FileOutputStream(Benchmark.outputFn, true), 8192 * 8), false, Benchmark.ENCODING);
			final String application = cmdl.getOptionValue("application");
			if (null != application) {
				mc = ((MonitoredClass) Class.forName(application).newInstance());
			} else {
				mc = new MonitoredClassThreaded();
			}
			final String clazzname = cmdl.getOptionValue("runnable");
			if (null != clazzname) {
				((Runnable) Class.forName(clazzname).newInstance()).run();
			}
		} catch (final Exception ex) { // NOCS (e.g., IOException, ParseException, NumberFormatException)
			new HelpFormatter().printHelp(Benchmark.class.getName(), cmdlOpts);
			System.out.println(ex.toString()); // NOPMD (Stacktrace)
			System.exit(-1);
		}
	}
}
