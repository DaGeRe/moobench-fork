#rm(list=ls(all=TRUE))
results_fn="results/raw"
outtxt_fn="results-text.txt"

configs.threads=c(1:6)
configs.loop=1
configs.recursion=c(10)
configs.labels=c("No Probe","Inactive Probe","Collecting Data","Writing Data")
configs.count=length(configs.labels)
results.count=200000
results.skip=100000

for (threads in configs.threads) {
  resultsBIG <- array(dim=c(length(configs.recursion),configs.count,threads*configs.loop*(results.count-results.skip)),dimnames=list(configs.recursion,configs.labels,c(1:(threads*configs.loop*(results.count-results.skip)))))
  for (cr in configs.recursion) {
    for (cc in (1:configs.count)) {
      for (cl in (1:configs.loop)) {
        results_fn_temp=paste(results_fn, "-", cl, "-", threads, "-", cc, ".csv", sep="")
        for (ct in (1:threads)) {
          results=read.csv2(results_fn_temp,nrows=(results.count-results.skip),skip=(ct-1)*results.count+results.skip,quote="",colClasses=c("NULL","numeric"),comment.char="",col.names=c("thread_id","duration_nsec"),header=FALSE)
          resultsBIG[(1:length(configs.recursion))[configs.recursion==cr],cc,c(((cl-1)*threads*(results.count-results.skip)+1):(cl*threads*(results.count-results.skip)))] <- results[["duration_nsec"]]/(1000)
        }
        rm(results,results_fn_temp)
      }
    }
  }
  for (cr in configs.recursion) {
    printvalues = matrix(nrow=7,ncol=configs.count,dimnames=list(c("mean","ci95%","md25%","md50%","md75%","max","min"),c(1:configs.count)))
    for (cc in (1:configs.count)) {
      printvalues["mean",cc]=mean(resultsBIG[(1:length(configs.recursion))[configs.recursion==cr],cc,c(1:(results.count-results.skip))])
      printvalues["ci95%",cc]=qnorm(0.975)*sd(resultsBIG[(1:length(configs.recursion))[configs.recursion==cr],cc,c(1:(results.count-results.skip))])/sqrt(length(resultsBIG[(1:length(configs.recursion))[configs.recursion==cr],cc,c(1:(results.count-results.skip))]))
      printvalues[c("md25%","md50%","md75%"),cc]=quantile(resultsBIG[(1:length(configs.recursion))[configs.recursion==cr],cc,c(1:(results.count-results.skip))],probs=c(0.25,0.5,0.75))
      printvalues["max",cc]=max(resultsBIG[(1:length(configs.recursion))[configs.recursion==cr],cc,c(1:(results.count-results.skip))])
      printvalues["min",cc]=min(resultsBIG[(1:length(configs.recursion))[configs.recursion==cr],cc,c(1:(results.count-results.skip))])
    }
    resultstext=formatC(printvalues,format="f",digits=4,width=8)
    print(resultstext)
    write(paste("Threads: ", threads),file=outtxt_fn,append=TRUE)
    write("response time",file=outtxt_fn,append=TRUE)
    write.table(resultstext,file=outtxt_fn,append=TRUE,quote=FALSE,sep="\t",col.names=FALSE)
  }
}
