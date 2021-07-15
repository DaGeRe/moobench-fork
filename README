The MooBench Monitoring Overhead Micro-Benchmark 
------------------------------------------------------------------------

Website: http://kieker-monitoring.net/MooBench

Note: Please note that we are currently reorganizing the project structure.
Thus, the documentation might be outdated.

The MooBench micro-benchmarks can be used to quantify the performance 
overhead caused by monitoring framework components. 

Currenly (directly) supported monitoring frameworks are:
* Kieker (http://kieker-monitoring.net)
* OpenTelemetry (https://opentelemetry.io/)
* SPASS-meter (https://github.com/SSEHUB/spassMeter.git)

The gradle buildfile is provided to prepare the benchmark. To build
the monitored application and copy it to the framework you want to benchmark,
just execute `./gradlew assemble`

All experiments are started with the provided "External Controller"
scripts. These scripts are available inside the respective bin/ 
directory. Currently only shell (.sh) scripts are provided. These 
scripts have been developed on Solaris environments. Thus, minor
adjustments might be required for common Linux operatong systems,
such as Ubuntu. Additionally, several Eclipse launch targets are 
provided for debugging purposes.

The default execution of the benchmark requires a 64Bit JVM!
However, this behavior can be changed in the respective .sh scripts.

Initially, the following steps are required:
1. Make sure, that you've installed R (http://www.r-project.org/) to 
   generate the results.
2. Compile the application by calling `./gradlew assemble`.

Execution of the micro-benchmark:
All benchmarks are started with calls of .sh scripts in the bin folder.
The top of the files include some configuration parameters, such as
* SLEEPTIME           between executions (default 30 seconds)
* NUM_LOOPS           number of repetitions (default 10)
* THREADS             concurrent benchmarking threads (default 1)
* MAXRECURSIONDEPTH   recursion up to this depth (default 10)
* TOTALCALLS          the duration of the benchmark (deafult 2,000,000 calls)
* METHODTIME          the time per monitored call (default 0 ns or 500 us)

Furthermore some JVM arguments can be adjusted:
* JAVAARGS            JVM Arguments (e.g., available memory)

Typical call (using Solaris):
$ nohup ./benchmark.sh & sleep 1;tail +0cf nohup.out


Analyzing the data:
===================
In the folder /bin/r are some R scripts provided to generate graphs to 
visualize the results. In the top the files, one can configure the 
required paths and the configuration used to analyze the data.
