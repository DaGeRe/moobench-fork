package moobench.tools.results;

import java.nio.file.Path;
import java.util.List;

import teetime.framework.AbstractProducerStage;

public class SpecialArrayElementStage extends AbstractProducerStage<Path> {

	private List<Path> resultCsvPaths;

	public SpecialArrayElementStage(List<Path> resultCsvPaths) {
		this.resultCsvPaths = resultCsvPaths;
	}

	@Override
	protected void execute() throws Exception {
		for(Path path : resultCsvPaths) {
			this.outputPort.send(path);
		}
		this.workCompleted();
	}
}
