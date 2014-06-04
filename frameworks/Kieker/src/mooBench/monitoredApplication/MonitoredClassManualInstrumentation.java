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

package mooBench.monitoredApplication;

import java.lang.management.ManagementFactory;
import java.lang.management.ThreadMXBean;

import kieker.common.record.flow.trace.TraceMetadata;
import kieker.common.record.flow.trace.operation.AfterOperationEvent;
import kieker.common.record.flow.trace.operation.AfterOperationFailedEvent;
import kieker.common.record.flow.trace.operation.BeforeOperationEvent;
import kieker.monitoring.core.controller.IMonitoringController;
import kieker.monitoring.core.controller.MonitoringController;
import kieker.monitoring.core.registry.TraceRegistry;
import kieker.monitoring.timer.ITimeSource;

/**
 * @author Jan Waller
 */
public final class MonitoredClassManualInstrumentation implements MonitoredClass {

	private static final IMonitoringController CTRLINST = MonitoringController.getInstance();
	private static final ITimeSource TIME = CTRLINST.getTimeSource();
	private static final TraceRegistry TRACEREGISTRY = TraceRegistry.INSTANCE;

	final ThreadMXBean threadMXBean = ManagementFactory.getThreadMXBean();

	/**
	 * Default constructor.
	 */
	public MonitoredClassManualInstrumentation() {
		// empty default constructor
	}

	public final long monitoredMethod(final long methodTime, final int recDepth) {
		if (!CTRLINST.isMonitoringEnabled()) {
			return this.monitoredMethod_actual(methodTime, recDepth);
		}
		final String signature = "public final long mooBench.monitoredApplication.MonitoredClassThreaded.monitoredMethod(long, int)";
		if (!CTRLINST.isProbeActivated(signature)) {
			return this.monitoredMethod_actual(methodTime, recDepth);
		}
		// common fields
		TraceMetadata trace = TRACEREGISTRY.getTrace();
		final boolean newTrace = trace == null;
		if (newTrace) {
			trace = TRACEREGISTRY.registerTrace();
			CTRLINST.newMonitoringRecord(trace);
		}
		final long traceId = trace.getTraceId();
		final String clazz = this.getClass().getName();
		// measure before execution
		CTRLINST.newMonitoringRecord(new BeforeOperationEvent(TIME.getTime(), traceId, trace.getNextOrderId(), signature, clazz));
		// execution of the called method
		final Object retval;
		try {
			retval = this.monitoredMethod_actual(methodTime, recDepth);
		} catch (final Throwable th) { // NOPMD NOCS (catch throw might ok here)
			// measure after failed execution
			CTRLINST.newMonitoringRecord(new AfterOperationFailedEvent(TIME.getTime(), traceId, trace.getNextOrderId(), signature, clazz,
					th.toString()));
			throw new RuntimeException(th);
		} finally {
			if (newTrace) { // close the trace
				TRACEREGISTRY.unregisterTrace();
			}
		}
		// measure after successful execution
		CTRLINST.newMonitoringRecord(new AfterOperationEvent(TIME.getTime(), traceId, trace.getNextOrderId(), signature, clazz));
		return (Long) retval;
	}

	public final long monitoredMethod_actual(final long methodTime, final int recDepth) {
		if (recDepth > 1) {
			return this.monitoredMethod(methodTime, recDepth - 1);
		} else {
			final long exitTime = this.threadMXBean.getCurrentThreadUserTime() + methodTime;
			long currentTime;
			do {
				currentTime = this.threadMXBean.getCurrentThreadUserTime();
			} while (currentTime < exitTime);
			return currentTime;
		}
	}

}
