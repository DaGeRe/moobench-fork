/***************************************************************************
 * Copyright (C) 2022 Kieker (https://kieker-monitoring.net)
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
package moobench.tools.results.stages;

import moobench.tools.results.data.Chart;
import teetime.stage.basic.AbstractFilter;

/**
 * @author Reiner Jung
 * @since 1.3.0
 */
public class TailChartStage extends AbstractFilter<Chart> {

    private final Integer window;

    public TailChartStage(final Integer window) {
        this.window = window;
    }

    @Override
    protected void execute(final Chart chart) throws Exception {
        if (this.window != null) {
            final int size = chart.getValues().size();
            if (size > this.window) {
                final Chart newChart = new Chart(chart.getName());
                newChart.getHeaders().addAll(chart.getHeaders());
                for (int i = size - this.window; i < size;i++) {
                    newChart.getValues().add(chart.getValues().get(i));
                }
                this.outputPort.send(newChart);
            } else {
                this.outputPort.send(chart);
            }
        } else {
            this.outputPort.send(chart);
        }
    }

}
