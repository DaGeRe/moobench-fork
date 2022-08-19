# -*- coding: utf-8 -*-
# standard import
import sys
import time
import configparser
import re
# instrumentation

# read argumetns
if len(sys.argv) < 2:
    print('Path to the benchmark configuration file was not provided.')

parser = configparser.ConfigParser()
parser.read(sys.argv[1])

total_calls =int(parser.get('Benchmark','total_calls'))
recursion_depth = int(parser.get('Benchmark','recursion_depth'))
method_time = int(parser.get('Benchmark','method_time'))
ini_path = parser.get('Benchmark','config_path')
inactive = parser.getboolean('Benchmark', 'inactive')
instrumentation_on = parser.getboolean('Benchmark', 'instrumentation_on')
approach = parser.getint('Benchmark', 'approach')
output_filename = parser.get('Benchmark', 'output_filename')

# debug
#print(f"total_calls = {total_calls}")
#print(f"recurison_depth = {recursion_depth}")
#print(f"method_time = {method_time}")

# instrument
from monitoring.controller import SingleMonitoringController
from tools.importhookast import InstrumentOnImportFinder
from tools.importhook import PostImportFinder
ex =[]
some_var = SingleMonitoringController(ini_path)
if instrumentation_on:
    # print ('Instrumentation is on.')
    if approach == 2:
        # print("2nd instrumentation approach is chosen")
        #if not inactive:
            #print("Instrumentation is activated")
        #else:
        #    print("Instrumentation is not activated")
        
        sys.meta_path.insert(0, InstrumentOnImportFinder(ignore_list=ex, empty=inactive, debug_on=False))
    else:
        #print("1st instrumentation approach is chosen")
        #if not inactive:
        #    print("Instrumentation is activated")
        #else:
        #    print("Instrumentation is not activated")
        
        pattern_object = re.compile('monitored_application')
        exclude_modules = list()
        sys.meta_path.insert(0, PostImportFinder(pattern_object, exclude_modules, empty = inactive))
#else:
#    print('Instrumentation is off')

import monitored_application

# setup
output_file = open(output_filename, "w")

thread_id = 0

start_ns = 0
stop_ns = 0
timings = []

# run experiment
for i in range(total_calls):
    start_ns = time.time_ns()
    monitored_application.monitored_method(method_time, recursion_depth)
    stop_ns = time.time_ns()
    timings.append(stop_ns-start_ns)
    if i%100000 == 0:
        print(timings[-1])
    
    output_file.write(f"{thread_id};{timings[-1]}\n")

output_file.close()

# end
