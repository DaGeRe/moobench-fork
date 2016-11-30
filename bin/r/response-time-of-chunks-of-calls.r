library("data.table")		# fread (fast csv reading)

pdf(file=sprintf("response-time-of-chunks-of-calls-%s.pdf", format(Sys.time(), format="%d-%B-%Y")))

filename = "response-time-of-chunks-of-calls.csv"
numFirstValuesToIgnore = 10000000
chunkSize = 10000

colors = c("red", "blue", "green", "black")
yVerticals = c(NA, 2, NA, 2)

# returns a data.table (by default) 
## which enhances/extends a data.frame
### which in turn is a list of vectors.
#### Each vector in the list represents a row with its column values.
csvTable = fread(filename, skip=numFirstValuesToIgnore)
# csvTable with an additional column "id" which contains the row numbers
csvTable[, id:=1:.N]

print(csvTable)

# default column name: "V" followed by the column number
thread <- csvTable[["V1"]]
time <- csvTable[["V2"]]
# groupedTime is a table with "id" and "V1"
groupedMaxTime <- csvTable[, max(V2), by=.((id-1)%/%chunkSize)]
groupedMeanTime <- csvTable[, mean(V2), by=.((id-1)%/%chunkSize)]
groupedMedianTime <- csvTable[, median(V2), by=.((id-1)%/%chunkSize)]
groupedMinTime <- csvTable[, min(V2), by=.((id-1)%/%chunkSize)]
memory <- csvTable[["V3"]]
gcActivity <- csvTable[["V4"]]

maxTimes <- groupedMaxTime[["V1"]]
meanTimes <- groupedMeanTime[["V1"]]
medianTimes <- groupedMedianTime[["V1"]]
minTimes <- groupedMinTime[["V1"]]

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

legend("top", c("max", "mean", "median", "min"), 
	fill=colors, 
	horiz=TRUE,
	title=sprintf("Each chunk of %d calls is aggregated via:", chunkSize)
)

i=1
plot(maxTimes, col=colors[i], type="l")
plot(meanTimes, col=colors[i+1], type="l")
plot(medianTimes, col=colors[i+2], type="l")
plot(minTimes, col=colors[i+3], type="l")


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
