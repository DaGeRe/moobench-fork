# README

Usage:
--total-calls -c     * Number of total method calls performed.
--method-time -m     * Time a method call takes.
--total-threads  -t  * Number of threads started.
--recursion-depth -d * Depth of recursion performed.
--output-filename -o * Filename of results file. Output is appended if file exists.
--quickstart -q        Skips initial garbage collection.
--force-terminate -f   Forces a termination at the end of the benchmark.
--runnable -r          Class implementing the Runnable interface. run() method is executed before the benchmark starts.
--application -a       Class implementing the MonitoredClass interface.
--benchmark-thread -b  Class implementing the BenchmarkingThread interface.


* = required parameter

It is sufficient to implement:
moobench \
   --application moobench.application.MonitoredClassSimple \
   --output-filename "${RAWFN}-${loop}-${recursion}-${index}.csv" \
   --total-calls "${TOTAL_NUM_OF_CALLS}" \
   --method-time "${METHOD_TIME}" \
   --total-threads 1 \
   --recursion-depth "${recursion}"

In a fest step it is sufficient do only have MonitoredClassSimple as we are
not going to use something else.


