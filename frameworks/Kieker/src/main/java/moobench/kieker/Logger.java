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
package moobench.kieker;

import java.io.IOException;

import moobench.benchmark.BenchmarkMain;

/**
 * @author Jan Waller
 */
public class Logger implements Runnable {

	public void run() {
		try {
			java.util.logging.LogManager.getLogManager().readConfiguration(
					BenchmarkMain.class.getClassLoader().getResourceAsStream("META-INF/kieker.logging.properties"));
		} catch (final IOException ex) {
			java.util.logging.Logger.getAnonymousLogger().log(java.util.logging.Level.SEVERE, "Could not load default logging.properties file", ex);
		}
	}
}
