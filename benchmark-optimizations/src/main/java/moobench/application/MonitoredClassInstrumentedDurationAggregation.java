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
public final class MonitoredClassInstrumentedDurationAggregation implements MonitoredClass {

	private static final IMonitoringController CTRLINST = MonitoringController.getInstance();
	private static final ControlFlowRegistry CFREGISTRY = ControlFlowRegistry.INSTANCE;
	private static final ITimeSource TIME = CTRLINST.getTimeSource();

	/**
	 * Default constructor.
	 */
	public MonitoredClassInstrumentedDurationAggregation() {
		// empty default constructor
	}

	@Override
	public final long monitoredMethod(final long methodTime, final int recDepth) {
		final String operationSignature = "moobench.application.MonitoredClassInstrumentedDuration.monitoredMethod(long,int)";
		final long _kieker_sourceInstrumentation_tin = TIME.getTime();
		try {
			return extracted_monitoredMethod(methodTime, recDepth);
		} finally {
			final long _kieker_sourceInstrumentation_tout = TIME.getTime();
			_kieker_sourceInstrumentation_method0Sum0 += _kieker_sourceInstrumentation_tout - _kieker_sourceInstrumentation_tin;
			if (_kieker_sourceInstrumentation_method0Counter0++ % 1000 == 0) {
				final String _kieker_sourceInstrumentation_signature = "public int de.dagere.peass.C0_0.method0()";
				final long _kieker_sourceInstrumentation_calculatedTout = _kieker_sourceInstrumentation_tin + _kieker_sourceInstrumentation_method0Sum0;
				CTRLINST.newMonitoringRecord(new DurationRecord(_kieker_sourceInstrumentation_signature,
						_kieker_sourceInstrumentation_tin, _kieker_sourceInstrumentation_calculatedTout));
				_kieker_sourceInstrumentation_method0Sum0 = 0;
			}
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

	private static int _kieker_sourceInstrumentation_method0Counter0;

	private static long _kieker_sourceInstrumentation_method0Sum0;

}
