#rm(list=ls(all=TRUE))
results_fn="raw"
outtxt_fn="results-text.txt"

configs.loop=10
configs.labels=c("No MOnitoring","Spassmeter")
configs.count=length(configs.labels)
results.count=2000000
results.skip=results.count/2

printvalues = matrix(nrow=7,ncol=configs.count,dimnames=list(c("mean","ci95%","md25%","md50%","md75%","max","min"),c(1:configs.count)))

cr=10
for (cc in (1:configs.count)) {
  resultsBIG <- c()
  for (cl in (1:configs.loop)) {
    results_fn_temp=paste(results_fn, "-", cl, "-", cr, "-", cc, ".csv", sep="")
    results=read.csv2(results_fn_temp,nrows=(results.count-results.skip),skip=results.skip,quote="",colClasses=c("NULL","numeric"),comment.char="",col.names=c("thread_id","duration_nsec"),header=FALSE)
    resultsBIG <- c(resultsBIG, results[["duration_nsec"]]/(1000))
    rm(results)
  }
  printvalues["mean",cc]=mean(resultsBIG)
  printvalues["ci95%",cc]=qnorm(0.975)*sd(resultsBIG)/sqrt(length(resultsBIG))
  printvalues[c("md25%","md50%","md75%"),cc]=quantile(resultsBIG,probs=c(0.25,0.5,0.75))
  printvalues["max",cc]=max(resultsBIG)
  printvalues["min",cc]=min(resultsBIG)
}
resultstext=formatC(printvalues,format="f",digits=4,width=8)
print(resultstext)
write("response time",file=outtxt_fn,append=TRUE)
write.table(resultstext,file=outtxt_fn,append=TRUE,quote=FALSE,sep="\t",col.names=FALSE)
