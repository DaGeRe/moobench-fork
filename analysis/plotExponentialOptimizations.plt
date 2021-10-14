set encoding iso_8859_1
set terminal pdf size 5,3

set datafile separator ";"

set out '../results/Kieker.pdf'

set title 'Kieker Method Execution Durations'

set xlabel 'Call Tree Depth'
set ylabel 'Duration {/Symbol m}s'

set out '../results/Kieker-Optimizations.pdf'

set title 'Kieker Optimizations Measurement Durations'

set xlabel 'Call Tree Depth'
set ylabel 'Duration {/Symbol m}s'

set key left top
	
plot '../results/evolution_Kieker-Optimizations.csv' u 1:2 w linespoint lc "red" title 'Baseline', \
	'../results/evolution_Kieker-Optimizations.csv' u 1:($2-$3):($2+$3) w filledcurves lc "red" notitle fs transparent solid 0.5, \
     '../results/evolution_Kieker-Optimizations.csv' u 1:4 w linespoint lc "dark-yellow" title 'Regular Kieker', \
	'../results/evolution_Kieker-Optimizations.csv' u 1:($4-$5):($4+$5) w filledcurves lc "dark-yellow" notitle fs transparent solid 0.5, \
     '../results/evolution_Kieker-Optimizations.csv' u 1:6 w linespoint lc "red" title 'Source Instrumentation', \
	'../results/evolution_Kieker-Optimizations.csv' u 1:($6-$7):($6+$7) w filledcurves lc "red" notitle fs transparent solid 0.5, \
     '../results/evolution_Kieker-Optimizations.csv' u 1:8 w linespoint lc "blue" title 'SynchronizedCircularFifoQueue', \
        '../results/evolution_Kieker-Optimizations.csv' u 1:($8-$9):($8+$9) w filledcurves lc "blue" notitle fs transparent solid 0.5, \
     '../results/evolution_Kieker-Optimizations.csv' u 1:10 w linespoint lc "green" title 'DurationRecord', \
        '../results/evolution_Kieker-Optimizations.csv' u 1:($10-$11):($10+$11) w filledcurves lc "green" notitle fs transparent solid 0.5, \
     '../results/evolution_Kieker-Optimizations.csv' u 1:12 w linespoint lc "purple" title 'Aggregated Writer', \
        '../results/evolution_Kieker-Optimizations.csv' u 1:($12-$13):($12+$13) w filledcurves lc "purple" notitle fs transparent solid 0.5

unset output


