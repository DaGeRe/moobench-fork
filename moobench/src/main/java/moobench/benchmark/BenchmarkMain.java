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

package moobench.benchmark;

import java.io.BufferedOutputStream;
import java.io.PrintStream;
import java.nio.file.Files;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.ParameterException;

import moobench.application.MonitoredClass;
import moobench.application.MonitoredClassThreaded;

/**
 * @author Jan Waller
 */
public final class BenchmarkMain {
	private static final String ENCODING = "UTF-8";

	private static PrintStream ps = null;
	private static String outputFn = null;
	private static int totalThreads = 0;
	private static int totalCalls = 0;
	private static long methodTime = 0;
	private static int recursionDepth = 0;
	private static boolean quickstart = false;
	private static boolean forceTerminate = false;
	private static MonitoredClass mc = null;

	private static BenchmarkParameter parameter = new BenchmarkParameter();

	private BenchmarkMain() {
	}

	public static void main(final String[] args) throws InterruptedException {

		// 1. Preparations
		BenchmarkMain.parseAndInitializeArguments(args);

		System.out.println(" # Experiment run configuration:"); // NOPMD (System.out)
		System.out.println(" # 1. Output filename " + BenchmarkMain.outputFn); // NOPMD (System.out)
		System.out.println(" # 2. Recursion Depth " + BenchmarkMain.recursionDepth); // NOPMD (System.out)
		System.out.println(" # 3. Threads " + BenchmarkMain.totalThreads); // NOPMD (System.out)
		System.out.println(" # 4. Total-Calls " + BenchmarkMain.totalCalls); // NOPMD (System.out)
		System.out.println(" # 5. Method-Time " + BenchmarkMain.methodTime); // NOPMD (System.out)

		// 2. Initialize Threads and Classes
		final CountDownLatch doneSignal = new CountDownLatch(BenchmarkMain.totalThreads);
		final BenchmarkingThread[] benchmarkingThreads = new BenchmarkingThread[BenchmarkMain.totalThreads];
		final Thread[] threads = new Thread[BenchmarkMain.totalThreads];
		for (int i = 0; i < BenchmarkMain.totalThreads; i++) {
			benchmarkingThreads[i] = new BenchmarkingThreadNano(BenchmarkMain.mc, BenchmarkMain.totalCalls,
					BenchmarkMain.methodTime, BenchmarkMain.recursionDepth, doneSignal);
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
		for (int i = 0; i < BenchmarkMain.totalThreads; i++) {
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
		System.out.println(" #    done (" + TimeUnit.MILLISECONDS.toSeconds(totalTime) + " s)"); // NOPMD
																									// (System.out)

		// 5. Print experiment statistics
		System.out.print(" # 7. Writing results ... "); // NOPMD (System.out)
		// CSV Format: configuration;order_index;Thread-ID;duration_nsec
		for (int h = 0; h < BenchmarkMain.totalThreads; h++) {
			final BenchmarkingThread thread = benchmarkingThreads[h];
			for (int i = 0; i < BenchmarkMain.totalCalls; i++) {
				final String line = threads[h].getName() + ";" + thread.print(i, ";");
				BenchmarkMain.ps.println(line);
			}
		}
		BenchmarkMain.ps.close();

		System.out.println("done"); // NOPMD (System.out)
		System.out.println(" # "); // NOPMD (System.out)

		if (forceTerminate) {
			System.exit(0);
		}
	}

	public static void parseAndInitializeArguments(final String[] argv) {
		JCommander commander = null;
		try {
			commander = JCommander.newBuilder().addObject(parameter).build();
			commander.parse(argv);

			BenchmarkMain.ps = new PrintStream(
					new BufferedOutputStream(Files.newOutputStream(parameter.getOutputFile().toPath()), 8192 * 8),
					false, BenchmarkMain.ENCODING);
			if (null != parameter.getApplicationClassname()) {
				mc = ((MonitoredClass) Class.forName(parameter.getApplicationClassname()).newInstance());
			} else {
				mc = new MonitoredClassThreaded();
			}
			if (null != parameter.getRunnableClassname()) {
				((Runnable) Class.forName(parameter.getRunnableClassname()).newInstance()).run();
			}
		} catch (ParameterException ex) {
			if (commander != null)
				commander.usage();
		} catch (final Exception ex) { // NOCS (e.g., IOException, ParseException,
										// NumberFormatException)
			if (commander != null) {
				commander.usage();
			}
			System.out.println(ex.toString()); // NOPMD (Stacktrace)
			System.exit(-1);
		}
	}
}
