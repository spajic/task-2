require './task-2'
# gem install benchmark-ips
# gem install kalibera
require 'benchmark/ips'

GC.disable

def cpu_benchmark
  Benchmark.ips do |bench|
    bench.warmup = 0
    %w[0065 0125 025 05 1 2].each do |size|
      bench.report("Process #{size}Mb") { work("data/data_large.#{size}.txt") }
    end

    bench.compare!
  end
end

def memory_allocation
  %w[0065 0125 025 05 1].each do |size|
    before = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    work("data/data_large.#{size}.txt")
    after = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    puts "Total memory for date_large.#{size}.txt: #{after - before} MB"
  end
end

memory_allocation
cpu_benchmark