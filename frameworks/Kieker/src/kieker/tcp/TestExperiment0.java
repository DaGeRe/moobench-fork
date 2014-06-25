/***************************************************************************
 * Copyright 2014 Kieker Project (http://kieker-monitoring.net)
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
import java.nio.ByteBuffer;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

// Command-Line:
// java -javaagent:lib/kieker-1.10-SNAPSHOT_aspectj.jar -Dkieker.monitoring.writer=kieker.monitoring.writer.tcp.TCPWriter -Dkieker.monitoring.writer.tcp.TCPWriter.QueueFullBehavior=1 -jar dist\MooBench.jar --recursiondepth 10 --totalthreads 1 --methodtime 0 --output-filename raw.csv --totalcalls 10000000
/**
 * @author Jan Waller
 */
public final class TestExperiment0 {
	private static final int PORT1 = 10133;
	private static final int PORT2 = 10134;

	final static AtomicInteger counter = new AtomicInteger(0);
	final static AtomicLong totalBytes = new AtomicLong(0);

	private TestExperiment0() {}

	public static void main(final String[] args) throws InterruptedException {
		final ScheduledThreadPoolExecutor executorService = new ScheduledThreadPoolExecutor(1);
		executorService.scheduleAtFixedRate(new Runnable() {
			public void run() {
				final int bytes = TestExperiment0.counter.getAndSet(0);
				totalBytes.addAndGet(bytes);
				if (bytes > (1024 * 1024)) {
					System.out.println("MB/s: " + (bytes / (1024 * 1024)));
				} else if (bytes > 1024) {
					System.out.println("KB/s: " + (bytes / 1024));
				} else {
					System.out.println(" B/s: " + bytes);
				}
			}
		}, 0, 1, TimeUnit.SECONDS);

		final Thread thread1 = new Thread(new SocketListener(PORT1));
		final Thread thread2 = new Thread(new SocketListener(PORT2));

		thread1.start();
		thread2.start();

		thread1.join();
		thread2.join();
		executorService.shutdown();
		System.out.println("Total bytes read: " + totalBytes.get());
	}
}

class SocketListener implements Runnable {
	private static final int MESSAGE_BUFFER_SIZE = 65535;
	private final int port;

	public SocketListener(final int port) {
		this.port = port;
	}

	public void run() {
		ServerSocketChannel serversocket = null;
		try {
			serversocket = ServerSocketChannel.open();
			serversocket.socket().bind(new InetSocketAddress(this.port));
			System.out.println("Connected: " + this.port);
			final SocketChannel socketChannel = serversocket.accept();
			final ByteBuffer buffer = ByteBuffer.allocateDirect(MESSAGE_BUFFER_SIZE);
			while (socketChannel.read(buffer) != -1) {
				buffer.flip();
				TestExperiment0.counter.addAndGet(buffer.remaining());
				buffer.clear();
			}
			socketChannel.close();
		} catch (final IOException ex) {
			System.err.println("Error while reading: " + ex);
		} finally {
			if (null != serversocket) {
				try {
					serversocket.close();
				} catch (final IOException e) {
					System.err.println("Failed to close TCP connection!" + e);
				}
			}
		}
	}
}
