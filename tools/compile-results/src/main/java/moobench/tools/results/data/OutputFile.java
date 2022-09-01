package moobench.tools.results.data;

import java.nio.file.Path;

public class OutputFile {

    Path filePath;
    String content;

    public OutputFile(final Path filePath, final String content) {
        this.filePath = filePath;
        this.content = content;
    }

    public Path getFilePath() {
        return this.filePath;
    }

    public String getContent() {
        return this.content;
    }

}
