package moobench.tools.results.data;

public class Measurements {
		
	private Double mean;
	private Double convidence;
	private Double standardDeviation;
	private Double lowerQuartile;
	private Double median;
	private Double upperQuartile;
	private Double max;
	private Double min;

	public Measurements(Double mean, Double standardDeviation, Double convidence, Double lowerQuartile, Double median, Double upperQuartile, Double min, Double max) {
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
		return mean;
	}
	
	/**
	 * Returns the convidence value, to get the convidence interval you need to compute the interval as
	 * [mean-convidence:mean+convidence]
	 * 
	 * @return convidence value
	 */
	public Double getConvidence() {
		return convidence;
	}
	
	public Double getStandardDeviation() {
		return standardDeviation;
	}
	
	public Double getLowerQuartile() {
		return lowerQuartile;
	}
	
	public Double getMedian() {
		return median;
	}
	
	public Double getUpperQuartile() {
		return upperQuartile;
	}
	
	public Double getMin() {
		return min;
	}
	
	public Double getMax() {
		return max;
	}

}
