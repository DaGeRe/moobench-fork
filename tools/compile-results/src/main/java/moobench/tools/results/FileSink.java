package moobench.tools.results;

import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.file.Files;

import moobench.tools.results.data.OutputFile;
import teetime.framework.AbstractConsumerStage;

public class FileSink extends AbstractConsumerStage<OutputFile> {

    @Override
    protected void execute(final OutputFile outputFile) throws Exception {
        try (final BufferedWriter writer = Files.newBufferedWriter(outputFile.getFilePath())) {
            writer.write(outputFile.getContent());
            writer.close();
        } catch(final IOException e) {
            this.logger.error("Cannot write file {}", outputFile.getFilePath().toString());
        }
    }

}
