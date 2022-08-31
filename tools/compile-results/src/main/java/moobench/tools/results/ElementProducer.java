/**
 * 
 */
package moobench.tools.results;

import java.util.List;

import teetime.framework.AbstractProducerStage;

/**
 * @author Reiner Jung
 * @param <O>
 * @since 1.3.0
 *
 * @param <O> type of the elements
 */
public class ElementProducer<O> extends AbstractProducerStage<O> {

	private List<O> elements;

	public ElementProducer(List<O> elements) {
		this.elements = elements;
	}
	
	@Override
	protected void execute() throws Exception {
		for (O element : elements) {
			this.outputPort.send(element);
		}
	}

}
