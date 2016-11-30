library("data.table")		# fread (fast csv reading)


#filename = "response-time-of-chunks-of-calls.csv"
filename = "results-with-memory/raw-1-10-5.csv"
#filename = "results/raw-1-10-5.csv"
pdf(file=sprintf("%s-%s.pdf", filename, format(Sys.time(), format="%d-%B-%Y")))
numFirstValuesToIgnore = 10000000

colors = c("red", "blue", "green", "black", "darkred", "darkviolet")

# returns a data.table (by default) 
## which enhances/extends a data.frame
### which in turn is a list of vectors.
#### Each vector in the list represents a row with its column values.
csvTable = fread(filename, skip=numFirstValuesToIgnore)

rowCount = csvTable[, .N]
cat(sprintf("\nYour input file contains %d lines.\n\n", rowCount))

chunkSize = rowCount/1000
cat(sprintf("The chunk size was set to %d calls.\n\n", chunkSize))

# csvTable with an additional column "id" which contains the row numbers (necessary for grouping; see below)
csvTable[, id:=1:.N]

print(csvTable)

# default column name: "V" followed by the column number
thread <- csvTable[["V1"]]
time <- csvTable[["V2"]]
memory <- csvTable[["V3"]]
gcActivity <- csvTable[["V4"]]

# grouped*Time is a table with "id" and "V1"
groupedMaxTime <- csvTable[, max(V2), by=.((id-1)%/%chunkSize)]
groupedMeanTime <- csvTable[, mean(V2), by=.((id-1)%/%chunkSize)]
groupedMedianTime <- csvTable[, median(V2), by=.((id-1)%/%chunkSize)]
groupedMinTime <- csvTable[, min(V2), by=.((id-1)%/%chunkSize)]

groupedMeanMemory = NULL
if (is.null(memory)) {
	groupedMeanMemory <- list()
} else {
	groupedMeanMemory <- csvTable[, mean(V3), by=.((id-1)%/%chunkSize)]
}

groupedSumGcActivity = NULL
if (is.null(gcActivity)) {
	groupedSumGcActivity <- list()
} else {
	groupedSumGcActivity <- csvTable[, sum(V4), by=.((id-1)%/%chunkSize)]
}

maxTimes <- groupedMaxTime[["V1"]]
meanTimes <- groupedMeanTime[["V1"]]
medianTimes <- groupedMedianTime[["V1"]]
minTimes <- groupedMinTime[["V1"]]

meanMemory <- groupedMeanMemory[["V1"]]

sumGcActivity <- groupedSumGcActivity[["V1"]]

##### start plotting #####

# increase the width of the plot (margin) due to multiple y-axes
#5.1,4.1,4.1,2.1			# default margin in R
par(mar = c(5.1+3,4.1,4.1+2,2.1+5))
# disable scientific number representation, e.g., 1e+07
options(scipen=10)

ts.plot(
	ts(maxTimes), ts(meanTimes), ts(medianTimes), ts(minTimes), 
	gpars = list(yaxt="n", xaxt="n"),
	col=colors, 
	type="l", 
	log="y", 
	xlab="Chunk",
	ylab="Response time (in us) of a chunk"
)
# display x-ticks with "th" as suffix
ticks <- axTicks(1)
axis(1, at = ticks, labels=sprintf("%dth", ticks))
# display y-ticks in micro seconds (so, we divide the current ticks by 1000)
ticks <- axTicks(2)
axis(2, at = ticks, labels=ticks/1000)

if (!is.null(memory)) {
par(new=T)
ts.plot(ts(meanMemory), 
	gpars = list(axes=FALSE, xaxt="n", yaxt="n"),
	col=colors[5],
	type="l",
	xlab="",
	ylab=""
)
# display y-ticks in mega bytes (so, we divide the current ticks by 1024*1024)
ticks <- axTicks(2)
axis(4, at = ticks, labels=sprintf("%.0f", ticks/(1024*1024)), col=colors[5])
mtext("Mean heap memory consumption (in MB) of a chunk", side=4, line=2)
}

if (!is.null(gcActivity)) {
par(new=T)
ts.plot(ts(sumGcActivity), 
		gpars = list(axes=FALSE, xaxt="n", yaxt="n"),
		col=colors[6],
		type="l",
		xlab="",
		ylab=""
)
# display y-ticks
ticks <- axTicks(2)
axis(4, at = ticks, labels=ticks, col=colors[6], line=4)
mtext("Sum GC collection count of a chunk", side=4, line=6)
}

# disable clipping (to not cut off the legends outside the plot)
par(xpd=TRUE)
legend("top", c("max", "mean", "median", "min"), 
	fill=colors, 
	horiz=TRUE,
	title=sprintf("Each chunk of %d calls is aggregated via:", chunkSize),
	inset=c(0,-0.16)
)

legend("bottom", c("mean heap", "sum gc"), 
	fill=colors[5:6], 
	horiz=TRUE,
	title=sprintf("Memory observations"),
	inset=c(0,-0.35)
)

# reset margin to default
par(mar = c(5.1,4.1,4.1,2.1))

i=1
plot(maxTimes, col=colors[i], type="l")
plot(meanTimes, col=colors[i+1], type="l")
plot(medianTimes, col=colors[i+2], type="l")
plot(minTimes, col=colors[i+3], type="l")
if (!is.null(memory)) {
	plot(meanMemory, col=colors[i+4], type="l")
}
if (!is.null(gcActivity)) {
	plot(sumGcActivity, col=colors[i+5], type="l")
}


### experimental code ###
#print("experimental code follows...")

#csvTable = fread(filename, skip=0, nrows=10)
#csvTable = fread(filename, skip=numFirstValuesToIgnore, select=c(1,2))
#csvTable = fread(filename, skip=numFirstValuesToIgnore, select=c("thread","time"))

#print(csvTable)

# increase the width of the plot (margin) due to multiple y-axes
#par(oma = c(0, 2, 0, 2))

# returns the column named "thread" as vector
#csvTable[["thread"]]

# returns the column with number 1 as vector
#csvTable[1]

#numRows = csvTable[, .N]

# default column name: "V" followed by the column number
#x <- seq(1:numRows)

#groupedTime <- csvTable[,c(V2),by=V1]
#print(groupedTime)

# x and y are each a list of values
#plot(x,y)
# y label is "-log_10(p)"
#plot(x,y, ylab=expression(-log[10](italic(p))))

# axis(..): side=2 means left side; side=4 means right side

#labels <- sapply(ticks, function(i) as.expression(bquote(10^ .(i))))
# labels <- c("a", "b", "c")

# write pdf
invisible(dev.off())
