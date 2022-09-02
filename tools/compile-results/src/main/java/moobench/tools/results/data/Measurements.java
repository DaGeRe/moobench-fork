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
package moobench.tools.results.data;

public class Measurements {

    private final Double mean;
    private final Double convidence;
    private final Double standardDeviation;
    private final Double lowerQuartile;
    private final Double median;
    private final Double upperQuartile;
    private final Double max;
    private final Double min;

    public Measurements(final Double mean, final Double standardDeviation, final Double convidence, final Double lowerQuartile, final Double median, final Double upperQuartile, final Double min, final Double max) {
        this.mean = mean;
        this.convidence = convidence;
        this.standardDeviation = standardDeviation;
        this.lowerQuartile = lowerQuartile;
        this.median = median;
        this.upperQuartile = upperQuartile;
        this.min = min;
        this.max = max;
    }

    public Double getMean() {
        return this.mean;
    }

    /**
     * Returns the convidence value, to get the convidence interval you need to compute the interval as
     * [mean-convidence:mean+convidence]
     *
     * @return convidence value
     */
    public Double getConvidence() {
        return this.convidence;
    }

    public Double getStandardDeviation() {
        return this.standardDeviation;
    }

    public Double getLowerQuartile() {
        return this.lowerQuartile;
    }

    public Double getMedian() {
        return this.median;
    }

    public Double getUpperQuartile() {
        return this.upperQuartile;
    }

    public Double getMin() {
        return this.min;
    }

    public Double getMax() {
        return this.max;
    }

}
