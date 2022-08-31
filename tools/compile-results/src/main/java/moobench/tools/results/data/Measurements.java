package moobench.tools.results.data;

public class Measurements {
		
	private double mean;
	private double convidence;
	private double standardDeviation;
	private double lowerQuartile;
	private double median;
	private double upperQuartile;
	private double max;
	private double min;

	public Measurements(double mean, double standardDeviation, double convidence, double lowerQuartile, double median, double upperQuartile, double min, double max) {
		this.mean = mean;
		this.convidence = convidence;
		this.standardDeviation = standardDeviation;
		this.lowerQuartile = lowerQuartile;
		this.median = median;
		this.upperQuartile = upperQuartile;
		this.min = min;
		this.max = max;
	}
	
	public double getMean() {
		return mean;
	}
	
	/**
	 * Returns the convidence value, to get the convidence interval you need to compute the interval as
	 * [mean-convidence:mean+convidence]
	 * 
	 * @return convidence value
	 */
	public double getConvidence() {
		return convidence;
	}
	
	public double getStandardDeviation() {
		return standardDeviation;
	}
	
	public double getLowerQuartile() {
		return lowerQuartile;
	}
	
	public double getMedian() {
		return median;
	}
	
	public double getUpperQuartile() {
		return upperQuartile;
	}
	
	public double getMin() {
		return min;
	}
	
	public double getMax() {
		return max;
	}

}
