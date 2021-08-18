The MooBench Monitoring Overhead Micro-Benchmark 
------------------------------------------------------------------------

Website: http://kieker-monitoring.net/MooBench

The MooBench micro-benchmarks can be used to quantify the performance overhead caused by monitoring framework components. 

Currenly (fully) supported monitoring frameworks are:
* Kieker (http://kieker-monitoring.net)
* OpenTelemetry (https://opentelemetry.io/)

Initially, the following steps are required:
1. Make sure, that you've installed R (http://www.r-project.org/) to generate the results (Ubuntu: `sudo apt install r-base`).
2. Compile the application by calling `./gradlew assemble`.

All experiments are started with the provided "External Controller" scripts. The following scripts are available
* for Kieker: In `frameworks/Kieker/scripts/benchmark.sh` for regular execution and `frameworks/Kieker/scripts/runExponentialSizes.sh` for execution of different call tree depth sizes
* for OpenTelemetry: `frameworks/opentelemetry/benchmark.sh` for regular execution and `frameworks/opentelemetry/runExponentialSizes.sh` for execution of different call tree depth sizes

All scripts have been tested on Ubuntu and Raspbian. 

The execution may be parameterized by the following environment variables:
* SLEEPTIME           between executions (default 30 seconds)
* NUM_LOOPS           number of repetitions (default 10)
* THREADS             concurrent benchmarking threads (default 1)
* MAXRECURSIONDEPTH   recursion up to this depth (default 10)
* TOTALCALLS          the duration of the benchmark (deafult 2,000,000 calls)
* METHODTIME          the time per monitored call (default 0 ns or 500 us)

If they are unset, the values are set via `frameworks/common-function.sh`.

Typical call (using Ubuntu):
$ export SLEEPTIME=1 && ./gradlew assemble && cd frameworks/opentelemetry/ && ./benchmark.sh


Analyzing the data:
===================
In the folder /bin/r are some R scripts provided to generate graphs to 
visualize the results. In the top the files, one can configure the 
required paths and the configuration used to analyze the data.
