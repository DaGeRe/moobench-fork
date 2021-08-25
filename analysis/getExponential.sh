function getSum {
	awk '{sum += $1; square += $1^2} END {print "Average: "sum/NR" Standard Deviation: "sqrt(square / NR - (sum/NR)^2)" Count: "NR}'
}

function getFileAverages {
	variants=$(ls $1 | grep raw | awk -F'[-.]' '{print $4}' | sort | uniq)
	for size in 2 4 8 16 32 64 128
	do
		for variant in $variants
		do
		        allExecutions=$(cat $1/raw-*-$size-$variant.csv | wc -l)
		        for file in $(ls $1/raw-*-$size-$variant.csv)
		        do
		                fileSize=$(cat $file | wc -l)
		                afterWarmup=$(($fileSize/2))
		                average=$(tail -n $afterWarmup $file | awk -F';' '{print $2}' | getSum | awk '{print $2}')
		                echo $variant";"$size";"$average
		        done
		done
	done
}

function getFrameworkEvolutionFile {
	folder=$1
	framework=$2
	getFileAverages $1/results-$framework/ > $RESULTFOLDER/$framework.csv
	variants=$(cat $RESULTFOLDER/$framework.csv | awk -F';' '{print $1}' | sort | uniq)
	for size in 2 4 8 16 32 64 128
	do
		echo -n "$size;"
		for variant in $variants
		do
			cat $RESULTFOLDER/$framework.csv | grep "^$variant;$size;" | awk -F';' '{print $3}' | getSum | awk '{print $2";"$5";"}' | tr -d "\n"
		done
		echo
	done > $RESULTFOLDER/evolution_$framework.csv
}

if [ "$#" -lt 1 ]; then
	echo "Please pass the folder where results-Kieker, results-OpenTelemetry and results-inspectIT are"
	exit 1
fi

if [ ! -d $1 ]; then
	echo "$1 should be a folder, but is not."
	exit 1
fi

RESULTFOLDER=../results
if [ -d $RESULTFOLDER ]
then
	rm -rf $RESULTFOLDER/* 
fi
mkdir -p $RESULTFOLDER

for framework in Kieker OpenTelemetry inspectIT
do
	echo "Analysing $framework"
	getFrameworkEvolutionFile $1 $framework
done

gnuplot -c plotExponential.plt
