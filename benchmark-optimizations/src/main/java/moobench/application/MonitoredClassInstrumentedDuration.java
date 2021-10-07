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

package moobench.application;

import de.dagere.kopeme.kieker.record.DurationRecord;
import kieker.monitoring.core.controller.IMonitoringController;
import kieker.monitoring.core.controller.MonitoringController;
import kieker.monitoring.core.registry.ControlFlowRegistry;
import kieker.monitoring.timer.ITimeSource;

/**
 * @author Jan Waller
 */
public final class MonitoredClassInstrumentedDuration implements MonitoredClass {

	private static final IMonitoringController CTRLINST = MonitoringController.getInstance();
	private static final ControlFlowRegistry CFREGISTRY = ControlFlowRegistry.INSTANCE;
	private static final ITimeSource TIME = CTRLINST.getTimeSource();

	/**
	 * Default constructor.
	 */
	public MonitoredClassInstrumentedDuration() {
		// empty default constructor
	}

	@Override
	public final long monitoredMethod(final long methodTime, final int recDepth) {
		final String operationSignature = "moobench.application.MonitoredClassInstrumentedDuration.monitoredMethod(long,int)";
		if (!CTRLINST.isProbeActivated(operationSignature)) {
			return extracted_monitoredMethod(methodTime, recDepth);
		}
		final long tin = TIME.getTime();
		try {
			return extracted_monitoredMethod(methodTime, recDepth);
		} finally {
			final long tout = TIME.getTime();
			CTRLINST.newMonitoringRecord(
					new DurationRecord(operationSignature, tin, tout));
		}

	}

	private long extracted_monitoredMethod(final long methodTime, final int recDepth) {
		if (recDepth > 1) {
			return this.monitoredMethod(methodTime, recDepth - 1);
		} else {
			final long exitTime = System.nanoTime() + methodTime;
			long currentTime;
			do {
				currentTime = System.nanoTime();
			} while (currentTime < exitTime);
			return currentTime;
		}
	}
}
