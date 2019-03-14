require './task-2.rb'
require 'memory_profiler'

report = MemoryProfiler.report do
  work('data/data_125k.txt')
end
report.pretty_print(scale_bytes: true)
