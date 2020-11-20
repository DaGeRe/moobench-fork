package moobench.kieker.tcp;

import kieker.analysis.source.tcp.MultipleConnectionTcpSourceStage;
import kieker.analysisteetime.plugin.filter.forward.CountingFilter;
import teetime.framework.Configuration;

public class TestConfiguration1 extends Configuration {

	public TestConfiguration1(int inputPort, int bufferSize) {
		MultipleConnectionTcpSourceStage source = new MultipleConnectionTcpSourceStage(inputPort, bufferSize, null);
		CountingFilter counting = new CountingFilter();
		
		connectPorts(source.getOutputPort(), counting.getInputPort());
	}
}
