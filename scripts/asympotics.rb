
    
require './task-2.rb'
require 'benchmark'
require 'benchmark/ips'

REAL_JSON_FILE = 'data/report_result.json'
def run_benchmark_ips
  Benchmark.ips do |bench|
    bench.warmup = 0
    bench.report("Process 0.25Mb") { work('data/data_025mb.txt', REAL_JSON_FILE) }
    bench.report("Process 0.5Mb") { work('data/data_05mb.txt', REAL_JSON_FILE) }
    bench.report("Process 1Mb") { work('data/data_1mb.txt', REAL_JSON_FILE) }
    bench.compare!
  end
end
DATAS = ['data/data_025mb.txt', 'data/data_05mb.txt', 'data/data_1mb.txt']

def run_benchmark_reltime
  DATAS.each do |filename|
    time = Benchmark.realtime do
      puts "#{filename}"
      work(filename, REAL_JSON_FILE)
    end
  puts "Finish in #{time.round(2)}"
  end
end
run_benchmark_reltime
run_benchmark_ips