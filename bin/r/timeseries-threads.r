#rm(list=ls(all=TRUE))
#data_fn="tmp/"
#folder_fn="results-benchmark-binary"
#results_fn=paste(data_fn,folder_fn,"/raw",sep="")
#output_fn=paste(data_fn,folder_fn,"/results-timeseries.pdf",sep="")

#configs.loop=10
#configs.recursion=c(10)
#configs.labels=c("No Probe","Deactivated Probe","Collecting Data","Writing Data")
#configs.colors=c("black","red","blue","green")
configs.count=length(configs.labels)

## We assume same amount of data in each category
#results.count=2000000
buckets.count=1000
buckets.size=results.count/buckets.count

## Configure Timeseries
#tsconf.min=0
#tsconf.max=50

pdf(output_fn, width=10, height=6.25, paper="special")

for (cr in configs.threads) {
  for (cl in (1:configs.loop)) {
    results.ts <- array(dim=c(buckets.count,configs.count))
    for (cc in (1:configs.count)) {
      results.bucket <- array(dim=c(buckets.count))
      results_fn_temp=paste(results_fn, "-", cl, "-", cr, "-", cc, ".csv", sep="")
      results=read.csv2(results_fn_temp,quote="",colClasses=c("NULL","numeric"),comment.char="",col.names=c("thread_id","duration_nsec"),nrows=results.count)
      results["rt_musec"]=results["duration_nsec"]/(1000)
      results$duration_nsec <- NULL
      for (ci in (1:buckets.count)) {
        results.bucket[ci] <- mean(results[(((ci-1)*buckets.size)+1):(ci*buckets.size),"rt_musec"])
      }
      results.ts[,cc]=ts(results.bucket,end=results.count,deltat=buckets.size)
      rm(results,results_fn_temp,results.bucket)
    }
    ts.plot(results.ts,gpars=list(ylim=c(tsconf.min,tsconf.max),col=configs.colors,xlab="Executions"))
    legend("topright",inset=c(0.01,0.01),legend=c(rev(configs.labels)),lty="solid",col=rev(configs.colors),bg="white",title="Mean execution time of ...",ncol=2)
    title(main=paste("Iteration: ", cl, "  Threads: ", cr),ylab=expression(paste("Execution Time (",mu,"s)")))
  }
}
invisible(dev.off())
