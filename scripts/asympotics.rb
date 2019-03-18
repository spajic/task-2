
    
require './task-2.rb'
require 'benchmark/ips'

REAL_JSON_FILE = 'data/report_result.json'
Benchmark.ips do |bench|
  bench.warmup = 0
  bench.report("Process 0.25Mb") { work('data/data_025mb.txt', REAL_JSON_FILE) }
  bench.report("Process 0.5Mb") { work('data/data_05mb.txt', REAL_JSON_FILE) }
  bench.report("Process 1Mb") { work('data/data_1mb.txt', REAL_JSON_FILE) }
  bench.compare!
end