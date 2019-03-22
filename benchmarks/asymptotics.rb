require './task-2.rb'
require 'benchmark/ips'

Benchmark.ips do |bench|
  bench.warmup = 0
  bench.report("Process 0.0625Mb") { work('data/data_62500.txt') }
  bench.report("Process 0.125Mb") { work('data/data_125k.txt') }
  bench.report("Process 0.25Mb") { work('data/data_250k.txt') }
  bench.report("Process 0.5Mb") { work('data/data_500k.txt') }
  bench.report("Process 1Mb") { work('data/data_1m.txt') }

  bench.compare!
end
