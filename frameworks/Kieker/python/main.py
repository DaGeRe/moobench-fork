# -*- coding: utf-8 -*-
# standard import
import sys
import time
# instrumentation
import tools.aspect
# read argumetns
total_calls =int(sys.argv[1])
recursion_depth = int(sys.argv[2])
method_time = int(sys.argv[3])
ini_path = sys.argv[4]



# instrument
from monitoring.controller import SingleMonitoringController
from tools.importhookast import InstrumentOnImportFinder
ex =[]
#sys.path.append("/home/serafim/Desktop/moo")
some_var = SingleMonitoringController(ini_path)
sys.meta_path.insert(0, InstrumentOnImportFinder(ignore_list=ex, debug_on=True))
import moo
print(moo.__dict__)

start_ns = 0
stop_ns = 0
timings = []
for i in range(total_calls):
    start_ns = time.time_ns()
    moo.monitored_method(method_time, recursion_depth)
    stop_ns = time.time_ns()
    timings.append(stop_ns-start_ns)
    if i%100000 ==0:
        print(timings[-1])

