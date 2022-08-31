############################################
# R - script to collect all moobench results
############################################

# these values are here only as documentation. The parameters are set by benchmark.sh
#rm(list=ls(all=TRUE))
#data_fn="data/"
#folder_fn="results-benchmark-binary"
#results_fn=paste(data_fn,folder_fn,"/raw",sep="")
#outtxt_fn=paste(data_fn,folder_fn,"/results-text.txt",sep="")
#results_fn="raw"
#out_yam_fn="results.yaml"

#########
# These are configuration parameters which are automatically prepended to this file by the benchmark.sh script.
# Therefore, they must not be set here. The following lines only serve as documentation.
#configs.loop=10
#configs.recursion=c(10)
#configs.labels=c("No Probe","Inactive Probe","Collecting Data","Writing Data (ASCII)", "Writing Data (Bin)")
#configs.framework_name="kieker-java"
#results.count=2000000
#results.skip=1000000

#bars.minval=500
#bars.maxval=600


##########
# Process configuration

# divisor 1 = nano, 1000 = micro, 1000000 = milli seconds
timeUnit <- 1000 

# number of Kieker writer configurations 
numberOfWriters <- length(configs.labels)
recursion_depth <- configs.recursion

numberOfValues <- configs.loop*(results.count-results.skip)
numbers <- c(1:(numberOfValues))
resultDimensionNames <- list(configs.labels, numbers)

# result values
resultsBIG <- array(dim=c(numberOfWriters, numberOfValues), dimnames=resultDimensionNames)

##########
# Create result

## "[ recursion , config , loop ]"

numOfRowsToRead <- results.count-results.skip

for (writer_idx in (1:numberOfWriters)) {
   recordsPerSecond = c()
   rpsLastDuration = 0
   rpsCount = 0
   file_idx <- writer_idx - 1

   # loop
   for (loop_counter in (1:configs.loop)) {
      results_fn_filepath <- paste(results_fn, "-", loop_counter, "-", recursion_depth, "-", file_idx, ".csv", sep="")
      message(results_fn_filepath)
      results <- read.csv2(results_fn_filepath, nrows=numOfRowsToRead, skip=results.skip, quote="", colClasses=c("NULL","numeric", "numeric", "numeric"), comment.char="", col.names=c("thread_id", "duration_nsec", "gc", "t"), header=FALSE)
      trx_idx <- c(1:numOfRowsToRead)
      resultsBIG[writer_idx,trx_idx] <- results[["duration_nsec"]]
   }
}

qnorm_value <- qnorm(0.975)

# print results
printDimensionNames <- list(c("mean","sd","ci95%","md25%","md50%","md75%","max","min"), c(1:numberOfWriters))
# row number == number of computed result values, e.g., mean, min, max
printvalues <- matrix(nrow=8, ncol=numberOfWriters, dimnames=printDimensionNames)

for (writer_idx in (1:numberOfWriters)) {
   idx_mult <- c(1:numOfRowsToRead)

   valuesBIG <- resultsBIG[writer_idx,idx_mult]/timeUnit

   printvalues["mean",writer_idx] <- mean(valuesBIG)
   printvalues["sd",writer_idx] <- sd(valuesBIG)
   printvalues["ci95%",writer_idx] <- qnorm_value*sd(valuesBIG)/sqrt(length(valuesBIG))
   printvalues[c("md25%","md50%","md75%"),writer_idx] <- quantile(valuesBIG, probs=c(0.25, 0.5, 0.75))
   printvalues["max",writer_idx] <- max(valuesBIG)
   printvalues["min",writer_idx] <- min(valuesBIG)
}
resultstext <- formatC(printvalues,format="f",digits=4,width=8)

print(resultstext)

currentTime <- as.numeric(Sys.time())

write(paste("kind:", configs.framework_name), file=out_yaml_fn,append=FALSE)
write("experiments:", file=out_yaml_fn, append=TRUE)
write(paste("- timestamp:", currentTime), file=out_yaml_fn, append=TRUE)
write("  measurements:", file=out_yaml_fn, append=TRUE)
for (writer_idx in (1:(numberOfWriters))) {
   write(paste("    ", configs.labels[writer_idx], ": [", 
      format(printvalues["mean",writer_idx], scientific=TRUE), ",",
      format(printvalues["sd",writer_idx], scientific=TRUE), ",", 
      format(printvalues["ci95%",writer_idx], scientific=TRUE), ",",
      format(printvalues["md25%",writer_idx], scientific=TRUE), ",",
      format(printvalues["md50%",writer_idx], scientific=TRUE), ",",
      format(printvalues["md75%",writer_idx], scientific=TRUE), ",",
      format(printvalues["max",writer_idx], scientific=TRUE), ",",
      format(printvalues["min",writer_idx], scientific=TRUE), "]"), file=out_yaml_fn, append=TRUE)
}
# end
