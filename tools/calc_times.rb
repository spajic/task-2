require './spec/spec_helper'
require_relative '../task-2'
require 'benchmark/ips'

Benchmark.ips do |x|
  x.warmup = 0

  Dir['./spec/fixtures/data_medium_*'].sort.each do |file|
    x.report(lines_in(file)) { work(file) }
  end

  x.compare!
end
