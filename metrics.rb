require 'benchmark/ips'
require './task-2'

def mac_os?
  RUBY_PLATFORM.match?(/darwin/)
end

def lines_nums
  (1..4).map { |x| 1000 * 2**x }
end

def populate(lines_num)
  if mac_os?
    system "zcat < data_large.txt.gz | head -n #{lines_num} > data_#{lines_num}.txt"
  else
    system "zcat data_large.txt.gz | head -n #{lines_num} > data_#{lines_num}.txt"
  end
end

lines_nums.each { |lines_num| populate(lines_num) }

Benchmark.ips do |bench|
  bench.warmup = 0

  lines_nums.each do |lines_num|
    bench.report("Process with #{lines_num} lines") { work("data_#{lines_num}.txt") }
  end

  bench.compare!
end
