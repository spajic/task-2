require 'benchmark'
require './task-2.rb'

def print_memory_usage
  "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
end

time = Benchmark.realtime do
  puts  "rss before work: #{print_memory_usage}"
  work('data/data_500k.txt')
  puts  "rss after work: #{print_memory_usage}"
end

puts "Finish in #{time.round(2)}"
