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
import kieker.common.record.flow.trace.operation.BeforeOperationEvent;
import kieker.monitoring.core.controller.IMonitoringController;
import kieker.monitoring.core.controller.MonitoringController;
import kieker.monitoring.core.registry.TraceRegistry;
import kieker.monitoring.timer.ITimeSource;

/**
 * @author Jan Waller
 */
public final class MonitoredClassManualInstrumentation implements MonitoredClass {

	private static final String SIGNATURE = "public final long mooBench.monitoredApplication.MonitoredClass.monitoredMethod(long, int)";
	private static final String CLAZZ = "mooBench.monitoredApplication.MonitoredClass";

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
		final boolean newTrace = MonitoredClassManualInstrumentation.triggerBefore();
		long retval;
		if (recDepth > 1) {
			retval = this.monitoredMethod(methodTime, recDepth - 1);
		} else {
			final long exitTime = this.threadMXBean.getCurrentThreadUserTime() + methodTime;
			long currentTime;
			do {
				currentTime = this.threadMXBean.getCurrentThreadUserTime();
			} while (currentTime < exitTime);
			retval = currentTime;
		}
		MonitoredClassManualInstrumentation.triggerAfter(newTrace);
		return retval;
	}

	private final static boolean triggerBefore() {
		if (!CTRLINST.isMonitoringEnabled()) {
			return false;
		}
		final String signature = SIGNATURE;
		if (!CTRLINST.isProbeActivated(signature)) {
			return false;
		}
		TraceMetadata trace = TRACEREGISTRY.getTrace();
		final boolean newTrace = trace == null;
		if (newTrace) {
			trace = TRACEREGISTRY.registerTrace();
			CTRLINST.newMonitoringRecord(trace);
		}
		final long traceId = trace.getTraceId();
		final String clazz = CLAZZ;
		CTRLINST.newMonitoringRecord(new BeforeOperationEvent(TIME.getTime(), traceId, trace.getNextOrderId(), signature, clazz));
		return newTrace;
	}

	private final static void triggerAfter(final boolean newTrace) {
		final TraceMetadata trace = TRACEREGISTRY.getTrace();
		final String signature = SIGNATURE;
		final String clazz = CLAZZ;
		CTRLINST.newMonitoringRecord(new AfterOperationEvent(TIME.getTime(), trace.getTraceId(), trace.getNextOrderId(), signature, clazz));
		if (newTrace) { // close the trace
			TRACEREGISTRY.unregisterTrace();
		}
	}
}
