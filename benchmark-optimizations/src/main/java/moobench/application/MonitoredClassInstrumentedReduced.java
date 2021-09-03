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

import de.dagere.kopeme.kieker.record.ReducedOperationExecutionRecord;
import kieker.monitoring.core.controller.IMonitoringController;
import kieker.monitoring.core.controller.MonitoringController;
import kieker.monitoring.core.registry.ControlFlowRegistry;
import kieker.monitoring.timer.ITimeSource;

/**
 * @author Jan Waller
 */
public final class MonitoredClassInstrumentedReduced implements MonitoredClass {

	private static final IMonitoringController CTRLINST = MonitoringController.getInstance();
	private static final ControlFlowRegistry CFREGISTRY = ControlFlowRegistry.INSTANCE;
	private static final ITimeSource TIME = CTRLINST.getTimeSource();

	/**
	 * Default constructor.
	 */
	public MonitoredClassInstrumentedReduced() {
		// empty default constructor
	}

	@Override
	public final long monitoredMethod(final long methodTime, final int recDepth) {
		final String operationSignature = "moobench.application.MonitoredClassInstrumentedReduced.monitoredMethod(long,int)";
		if (!CTRLINST.isProbeActivated(operationSignature)) {
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

		// common fields
		final boolean entrypoint;
		final int ess; // this is the height in the dynamic call tree of this execution
		long traceId = CFREGISTRY.recallThreadLocalTraceId(); // traceId, -1 if entry point
		if (traceId == -1) {
			entrypoint = true;
			traceId = CFREGISTRY.getAndStoreUniqueThreadLocalTraceId();
			CFREGISTRY.storeThreadLocalESS(1); // next operation is ess + 1
			ess = 0;
		} else {
			entrypoint = false;
			ess = CFREGISTRY.recallAndIncrementThreadLocalESS(); // ess >= 0
			if (ess == -1) {
				CTRLINST.terminateMonitoring();
			}
		}
		// measure before
		final long tin = TIME.getTime();
		try {
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
		} finally {
			final long tout = TIME.getTime();
			CTRLINST.newMonitoringRecord(
					new ReducedOperationExecutionRecord(operationSignature, tin, tout));
			// cleanup
			if (entrypoint) {
				CFREGISTRY.unsetThreadLocalTraceId();
				CFREGISTRY.unsetThreadLocalESS();
			} else {
				CFREGISTRY.storeThreadLocalESS(ess); // next operation is ess
			}
		}

	}
}
