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

package moobench.kieker.tcp;

import teetime.framework.Execution;

// Command-Line:
// java -javaagent:lib/kieker-1.10-SNAPSHOT_aspectj.jar -Dkieker.monitoring.writer=kieker.monitoring.writer.tcp.TCPWriter -Dkieker.monitoring.writer.tcp.TCPWriter.QueueFullBehavior=1 -jar dist\OverheadEvaluationMicrobenchmark.jar --recursiondepth 10 --totalthreads 1 --methodtime 0 --output-filename raw.csv --totalcalls 10000000
/**
 * @author Jan Waller
 */
public final class TestExperiment1 {

	private TestExperiment1() {}

	public static void main(final String[] args) {
		TestConfiguration1 config = new TestConfiguration1(Integer.parseInt(args[0]), 8192);
		Execution<TestConfiguration1> execution = new Execution<TestConfiguration1>(config);
		execution.executeBlocking();
	}
}
