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
