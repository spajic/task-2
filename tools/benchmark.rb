require './spec/spec_helper'
require_relative '../task-2'
require 'benchmark'

def print_memory_usage
  "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
end

time = Benchmark.realtime do
  puts  "rss before concatenation: #{print_memory_usage}"
  # work('./spec/fixtures/data_medium-10k.txt')
  work('./spec/fixtures/data_large.txt')
  puts  "rss after concatenation: #{print_memory_usage}"
end.round(4)

puts "Takes #{time} sec"
