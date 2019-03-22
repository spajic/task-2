require './task-2.rb'
require 'memory_profiler'

GC.disable
report = MemoryProfiler.report do
  work('data/data_large.05.txt')
end
report.pretty_print(scale_bytes: true)