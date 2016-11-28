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

package mooBench.benchmark;

import java.lang.management.GarbageCollectorMXBean;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.util.List;
import java.util.concurrent.CountDownLatch;

import mooBench.monitoredApplication.MonitoredClass;

/**
 * @author Jan Waller, Aike Sass, Christian Wulf
 */
public final class BenchmarkingThreadNano implements BenchmarkingThread {

  private final MonitoredClass mc;
  private final CountDownLatch doneSignal;
  private final int totalCalls;
  private final long methodTime;
  private final int recursionDepth;

  private final long[] timings;

  private final long[] usedHeapMemory;
  private final MemoryMXBean memory;

  private final List<GarbageCollectorMXBean> collector;

  public BenchmarkingThreadNano(final MonitoredClass mc, final int totalCalls,
      final long methodTime, final int recursionDepth, final CountDownLatch doneSignal) {
    this.mc = mc;
    this.doneSignal = doneSignal;
    this.totalCalls = totalCalls;
    this.methodTime = methodTime;
    this.recursionDepth = recursionDepth;
    // for monitoring execution times
    this.timings = new long[totalCalls];
    // for monitoring memory consumption
    this.memory = ManagementFactory.getMemoryMXBean();
    this.usedHeapMemory = new long[totalCalls];
    // for monitoring the garbage collector
    this.collector = ManagementFactory.getGarbageCollectorMXBeans();
  }

  public String print(final int index, final String separatorString) {
    return "" + this.timings[index] /* + separatorString + this.usedHeapMemory[index] */;
  }

  public final void run() {
    long start_ns;
    long stop_ns;
    final long gcBefore;
    final long gcAfter;

    for (int i = 0; i < this.totalCalls; i++) {
      // gcBefore = this.computeGcCollectionCount();
      start_ns = this.getCurrentTimestamp();

      this.mc.monitoredMethod(this.methodTime, this.recursionDepth);

      stop_ns = this.getCurrentTimestamp();
      // gcAfter = this.computeGcCollectionCount();

      // save execution time
      this.timings[i] = stop_ns - start_ns;
      if ((i % 100000) == 0) {
        System.out.println(i); // NOPMD (System.out)
      }
      // save heap memory
      this.usedHeapMemory[i] = this.memory.getHeapMemoryUsage().getUsed();
    }

    this.doneSignal.countDown();
  }

  private long computeGcCollectionCount() {
    long count = 0;
    for (final GarbageCollectorMXBean bean : this.collector) {
      count += bean.getCollectionCount();
      // bean.getCollectionTime()
    }
    return count;
  }

  private long getCurrentTimestamp() {
    // alternatively: System.currentTimeMillis();
    return System.nanoTime();
  }

}
