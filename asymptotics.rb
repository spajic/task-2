require './task-2.rb'
require 'benchmark/ips'

Benchmark.ips do |bench|
  bench.warmup = 0
  bench.report('Process 1Mb') { work('data/data_1MB.txt') }
  bench.report('Process 4Mb') { work('data/data_4MB.txt') }
  bench.report('Process 10Mb') { work('data/data_10MB.txt') }

  bench.compare!
end
