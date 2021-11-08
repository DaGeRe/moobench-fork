package moobench.tools.receiver;

import kieker.analysis.source.rewriter.NoneTraceMetadataRewriter;
import kieker.analysis.source.tcp.MultipleConnectionTcpSourceStage;
import kieker.analysisteetime.plugin.filter.forward.CountingFilter;
import teetime.framework.Configuration;

public class ReceiverConfiguration extends Configuration {

	public ReceiverConfiguration(final int inputPort, final int bufferSize) {
		MultipleConnectionTcpSourceStage source = new MultipleConnectionTcpSourceStage(inputPort, bufferSize, new NoneTraceMetadataRewriter());
		CountingFilter counting = new CountingFilter();
		
		connectPorts(source.getOutputPort(), counting.getInputPort());
	}
}
