/***************************************************************************
 * Copyright 2013 Kieker Project (http://kieker-monitoring.net)
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

package kieker.tcp;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.BufferUnderflowException;
import java.nio.ByteBuffer;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import kieker.analysis.AnalysisController;
import kieker.analysis.IAnalysisController;
import kieker.analysis.IProjectContext;
import kieker.analysis.exception.AnalysisConfigurationException;
import kieker.analysis.plugin.annotation.OutputPort;
import kieker.analysis.plugin.annotation.Plugin;
import kieker.analysis.plugin.annotation.Property;
import kieker.analysis.plugin.reader.AbstractReaderPlugin;
import kieker.common.configuration.Configuration;
import kieker.common.exception.MonitoringRecordException;
import kieker.common.logging.Log;
import kieker.common.logging.LogFactory;
import kieker.common.record.AbstractMonitoringRecord;
import kieker.common.record.IMonitoringRecord;
import kieker.common.record.misc.RegistryRecord;
import kieker.common.util.registry.ILookup;
import kieker.common.util.registry.Lookup;

// Command-Line:
// java -javaagent:lib/kieker-1.8-SNAPSHOT_aspectj.jar -Dkieker.monitoring.writer=kieker.monitoring.writer.tcp.TCPWriter -Dkieker.monitoring.writer.tcp.TCPWriter.QueueFullBehavior=1 -jar dist\OverheadEvaluationMicrobenchmark.jar --recursiondepth 10 --totalthreads 1 --methodtime 0 --output-filename raw.csv --totalcalls 10000000
/**
 * 
 * @author Jan Waller
 * 
 * @since 1.8
 */
public final class TestExperiment1 {
	private static final Log LOG = LogFactory.getLog(TestExperiment1.class);

	private TestExperiment1() {}

	public static void main(final String[] args) {
		final IAnalysisController analysisController = new AnalysisController("TCPThroughput");
		TestExperiment1.createAndConnectPlugins(analysisController);
		try {
			analysisController.run();
		} catch (final AnalysisConfigurationException ex) {
			TestExperiment1.LOG.error("Failed to start the example project.", ex);
		}
	}

	private static void createAndConnectPlugins(final IAnalysisController analysisController) {
		final Configuration readerConfig = new Configuration();
		// readerConfig.setProperty(TCPReader.CONFIG_PROPERTY_NAME_PORT1, 10333);
		// readerConfig.setProperty(TCPReader.CONFIG_PROPERTY_NAME_PORT2, 10334);
		final TCPCountingReader reader = new TCPCountingReader(readerConfig, analysisController);
		reader.getName(); // to remove unused warning
	}
}

/**
 * 
 * @author Jan Waller
 * 
 * @since 1.8
 */
@Plugin(description = "A reader which reads records from a TCP port",
		outputPorts = {
			@OutputPort(name = TCPCountingReader.OUTPUT_PORT_NAME_RECORDS, eventTypes = { IMonitoringRecord.class }, description = "Output Port of the TCPReader")
		},
		configuration = {
			@Property(name = TCPCountingReader.CONFIG_PROPERTY_NAME_PORT1, defaultValue = "10133",
					description = "The first port of the server used for the TCP connection."),
			@Property(name = TCPCountingReader.CONFIG_PROPERTY_NAME_PORT2, defaultValue = "10134",
					description = "The second port of the server used for the TCP connection.")
		})
final class TCPCountingReader extends AbstractReaderPlugin {

	/** The name of the output port delivering the received records. */
	public static final String OUTPUT_PORT_NAME_RECORDS = "monitoringRecords";

	/** The name of the configuration determining the TCP port. */
	public static final String CONFIG_PROPERTY_NAME_PORT1 = "port1";
	/** The name of the configuration determining the TCP port. */
	public static final String CONFIG_PROPERTY_NAME_PORT2 = "port2";

	private static final int MESSAGE_BUFFER_SIZE = 65535;

	static final Log LOG = LogFactory.getLog(TCPCountingReader.class);

	private final int port1;
	private final int port2;
	private final ILookup<String> stringRegistry = new Lookup<String>();

	final AtomicInteger counter = new AtomicInteger(0);

	public TCPCountingReader(final Configuration configuration, final IProjectContext projectContext) {
		super(configuration, projectContext);
		this.port1 = this.configuration.getIntProperty(CONFIG_PROPERTY_NAME_PORT1);
		this.port2 = this.configuration.getIntProperty(CONFIG_PROPERTY_NAME_PORT2);
	}

	@Override
	public boolean init() {
		final ScheduledExecutorService executorService = new ScheduledThreadPoolExecutor(1);
		executorService.scheduleAtFixedRate(new Runnable() {
			public void run() {
				LOG.info("Records/s: " + TCPCountingReader.this.counter.getAndSet(0));
			}
		}, 0, 1, TimeUnit.SECONDS);

		final TCPStringReader tcpStringReader = new TCPStringReader(this.port2, this.stringRegistry);
		tcpStringReader.start();
		return super.init();
	}

	@Override
	public Configuration getCurrentConfiguration() {
		final Configuration configuration = new Configuration();
		configuration.setProperty(CONFIG_PROPERTY_NAME_PORT1, Integer.toString(this.port1));
		configuration.setProperty(CONFIG_PROPERTY_NAME_PORT2, Integer.toString(this.port2));
		return configuration;
	}

	public boolean read() {
		ServerSocketChannel serversocket = null;
		try {
			serversocket = ServerSocketChannel.open();
			serversocket.socket().bind(new InetSocketAddress(this.port1));
			if (LOG.isDebugEnabled()) {
				LOG.debug("Listening on port " + this.port1);
			}
			// BEGIN also loop this one?
			final SocketChannel socketChannel = serversocket.accept();
			final ByteBuffer buffer = ByteBuffer.allocateDirect(MESSAGE_BUFFER_SIZE);
			while (socketChannel.read(buffer) != -1) {
				buffer.flip();
				// System.out.println("Reading, remaining:" + buffer.remaining());
				try {
					while (buffer.hasRemaining()) {
						buffer.mark();
						final int clazzid = buffer.getInt();
						final long loggingTimestamp = buffer.getLong();
						final IMonitoringRecord record;
						try { // NOCS (Nested try-catch)
							record = AbstractMonitoringRecord.createFromByteBuffer(clazzid, buffer, this.stringRegistry);
							record.setLoggingTimestamp(loggingTimestamp);
							// super.deliver(OUTPUT_PORT_NAME_RECORDS, record);
							this.counter.incrementAndGet();
						} catch (final MonitoringRecordException ex) {
							LOG.error("Failed to create record.", ex);
						}
					}
					buffer.clear();
				} catch (final BufferUnderflowException ex) {
					buffer.reset();
					// System.out.println("Underflow, remaining:" + buffer.remaining());
					buffer.compact();
				}
			}
			// System.out.println("Channel closing...");
			socketChannel.close();
			// END also loop this one?
		} catch (final IOException ex) {
			LOG.error("Error while reading", ex);
			return false;
		} finally {
			if (null != serversocket) {
				try {
					serversocket.close();
				} catch (final IOException e) {
					if (LOG.isDebugEnabled()) {
						LOG.debug("Failed to close TCP connection!", e);
					}
				}
			}
		}
		return true;
	}

	public void terminate(final boolean error) {
		LOG.info("Shutdown of TCPReader requested.");
	}
}

/**
 * 
 * @author Jan Waller
 * 
 * @since 1.8
 */
class TCPStringReader extends Thread {

	private static final int MESSAGE_BUFFER_SIZE = 65535;

	private static final Log LOG = LogFactory.getLog(TCPStringReader.class);

	private final int port;
	private final ILookup<String> stringRegistry;

	public TCPStringReader(final int port, final ILookup<String> stringRegistry) {
		this.port = port;
		this.stringRegistry = stringRegistry;
	}

	@Override
	public void run() {
		ServerSocketChannel serversocket = null;
		try {
			serversocket = ServerSocketChannel.open();
			serversocket.socket().bind(new InetSocketAddress(this.port));
			if (LOG.isDebugEnabled()) {
				LOG.debug("Listening on port " + this.port);
			}
			// BEGIN also loop this one?
			final SocketChannel socketChannel = serversocket.accept();
			final ByteBuffer buffer = ByteBuffer.allocateDirect(MESSAGE_BUFFER_SIZE);
			while (socketChannel.read(buffer) != -1) {
				buffer.flip();
				try {
					while (buffer.hasRemaining()) {
						buffer.mark();
						RegistryRecord.registerRecordInRegistry(buffer, this.stringRegistry);
					}
					buffer.clear();
				} catch (final BufferUnderflowException ex) {
					buffer.reset();
					buffer.compact();
				}
			}
			socketChannel.close();
			// END also loop this one?
		} catch (final IOException ex) {
			LOG.error("Error while reading", ex);
		} finally {
			if (null != serversocket) {
				try {
					serversocket.close();
				} catch (final IOException e) {
					if (LOG.isDebugEnabled()) {
						LOG.debug("Failed to close TCP connection!", e);
					}
				}
			}
		}
	}

}
