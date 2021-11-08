set encoding iso_8859_1
set terminal pdf size 8,5

set datafile separator ";"

set out '../results/Kieker.pdf'

set title 'Kieker Method Execution Durations'

set xlabel 'Call Tree Depth'
set ylabel 'Duration {/Symbol m}s'

set key right center
	
plot '../results/evolution_Kieker.csv' u 1:2 w linespoint lc "red" title 'Baseline', \
	'../results/evolution_Kieker.csv' u 1:($2-$3):($2+$3) w filledcurves lc "red" notitle fs transparent solid 0.5, \
     '../results/evolution_Kieker.csv' u 1:4 w linespoint lc "yellow" title 'Deactivated Probe', \
	'../results/evolution_Kieker.csv' u 1:($4-$5):($4+$5) w filledcurves lc "yellow" notitle fs transparent solid 0.5, \
     '../results/evolution_Kieker.csv' u 1:10 w linespoint lc "red" title 'Logging (Binary)', \
	'../results/evolution_Kieker.csv' u 1:($10-$11):($10+$11) w filledcurves lc "red" notitle fs transparent solid 0.5, \
     '../results/evolution_Kieker.csv' u 1:12 w linespoint lc "blue" title 'TCP', \
        '../results/evolution_Kieker.csv' u 1:($12-$13):($12+$13) w filledcurves lc "blue" notitle fs transparent solid 0.5
#     '../results/evolution_Kieker.csv' u 1:8 w linespoint lc "green" title 'Logging (Text)', \
#	'../results/evolution_Kieker.csv' u 1:($8-$9):($8+$9) w filledcurves lc "green" notitle fs transparent solid 0.5, \
# Activate this, if text logging should be displayed (very big, so disabled by default)	
	
unset output

set out '../results/OpenTelemetry.pdf'

set title 'OpenTelemetry Method Execution Durations'

set xlabel 'Call Tree Depth'
set ylabel 'Duration {/Symbol m}s'

set key right center
	
plot '../results/evolution_OpenTelemetry.csv' u 1:2 w linespoint lc "red" title 'Baseline', \
	'../results/evolution_OpenTelemetry.csv' u 1:($2-$3):($2+$3) w filledcurves lc "red" notitle fs transparent solid 0.5, \
     '../results/evolution_OpenTelemetry.csv' u 1:4 w linespoint lc "yellow" title 'No Logging', \
	'../results/evolution_OpenTelemetry.csv' u 1:($4-$5):($4+$5) w filledcurves lc "yellow" notitle fs transparent solid 0.5, \
     '../results/evolution_OpenTelemetry.csv' u 1:8 w linespoint lc "red" title 'Zipkin', \
	'../results/evolution_OpenTelemetry.csv' u 1:($8-$9):($8+$9) w filledcurves lc "red" notitle fs transparent solid 0.5, \
     '../results/evolution_OpenTelemetry.csv' u 1:10 w linespoint lc "blue" title 'Prometheus', \
        '../results/evolution_OpenTelemetry.csv' u 1:($10-$11):($10+$11) w filledcurves lc "blue" notitle fs transparent solid 0.5

#    'evolution_OpenTelemetry.csv' u 1:6 w linespoint lc "green" title 'Logging (Text)', \
#	'evolution_OpenTelemetry.csv' u 1:($6-$7):($6+$7) w filledcurves lc "green" notitle fs transparent solid 0.5, \
# Activate this, if text logging should be displayed (very big, so disabled by default)	
	
unset output

set out '../results/inspectIT.pdf'

set title 'inspectIT Method Execution Durations'

set xlabel 'Call Tree Depth'
set ylabel 'Duration {/Symbol m}s'

set key right center
	
plot '../results/evolution_inspectIT.csv' u 1:2 w linespoint lc "red" title 'Baseline', \
	'../results/evolution_inspectIT.csv' u 1:($2-$3):($2+$3) w filledcurves lc "red" notitle fs transparent solid 0.5, \
     '../results/evolution_inspectIT.csv' u 1:4 w linespoint lc "yellow" title 'No Logging', \
	'../results/evolution_inspectIT.csv' u 1:($4-$5):($4+$5) w filledcurves lc "yellow" notitle fs transparent solid 0.5, \
     '../results/evolution_inspectIT.csv' u 1:6 w linespoint lc "red" title 'Zipkin', \
	'../results/evolution_inspectIT.csv' u 1:($6-$7):($6+$7) w filledcurves lc "red" notitle fs transparent solid 0.5, \
     '../results/evolution_inspectIT.csv' u 1:8 w linespoint lc "blue" title 'Prometheus', \
        '../results/evolution_inspectIT.csv' u 1:($8-$9):($8+$9) w filledcurves lc "blue" notitle fs transparent solid 0.5

	
unset output

set terminal pdf size 5,3

set out '../results/overview.pdf'

set title 'Overview of Method Execution Durations'

set xlabel 'Call Tree Depth'
set ylabel 'Duration {/Symbol m}s'

set key left top
	
plot '../results/evolution_inspectIT.csv' u 1:2 w linespoint lc "red" title 'Baseline', \
	'../results/evolution_inspectIT.csv' u 1:($2-$3):($2+$3) w filledcurves lc "red" notitle fs transparent solid 0.5, \
     '../results/evolution_Kieker.csv' u 1:12 w linespoint lc "blue" title 'Kieker (TCP)', \
        '../results/evolution_Kieker.csv' u 1:($12-$13):($12+$13) w filledcurves lc "blue" notitle fs transparent solid 0.5, \
     '../results/evolution_inspectIT.csv' u 1:6 w linespoint lc rgb "#c66900" title 'inspectIT (Zipkin)', \
	'../results/evolution_inspectIT.csv' u 1:($6-$7):($6+$7) w filledcurves lc rgb "#c66900" notitle fs transparent solid 0.5, \
     '../results/evolution_OpenTelemetry.csv' u 1:8 w linespoint lc "green" title 'OpenTelemetry (Zipkin)', \
	'../results/evolution_OpenTelemetry.csv' u 1:($8-$9):($8+$9) w filledcurves lc "green" notitle fs transparent solid 0.5

	
unset output

set out '../results/overview_opentelemetry.pdf'

set title 'Overview of Method Execution Durations'

set xlabel 'Call Tree Depth'
set ylabel 'Duration {/Symbol m}s'

set key left top
	
plot '../results/evolution_inspectIT.csv' u 1:2 w linespoint lc "red" title 'Baseline', \
	'../results/evolution_inspectIT.csv' u 1:($2-$3):($2+$3) w filledcurves lc "red" notitle fs transparent solid 0.5, \
     '../results/evolution_OpenTelemetry.csv' u 1:4 w linespoint lc "blue" title 'OpenTelemetry (No Logging)', \
	'../results/evolution_OpenTelemetry.csv' u 1:($4-$5):($4+$5) w filledcurves lc "blue" notitle fs transparent solid 0.5, \
     '../results/evolution_inspectIT.csv' u 1:6 w linespoint lc rgb "#c66900" title 'inspectIT (Zipkin)', \
	'../results/evolution_inspectIT.csv' u 1:($6-$7):($6+$7) w filledcurves lc rgb "#c66900" notitle fs transparent solid 0.5, \
     '../results/evolution_OpenTelemetry.csv' u 1:8 w linespoint lc "green" title 'OpenTelemetry (Zipkin)', \
	'../results/evolution_OpenTelemetry.csv' u 1:($8-$9):($8+$9) w filledcurves lc "green" notitle fs transparent solid 0.5

	
unset output
