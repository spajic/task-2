require 'minitest/benchmark'
require 'minitest/autorun'
require './task-2'

class BenchTest < MiniTest::Benchmark
  def self.bench_range
    [1_000, 10_000, 100_000]
  end

  def bench_algorithm
    assert_performance_linear 0.9999 do |n|
      algorithm(n)
    end
  end

  def algorithm(lines_num)
    system "zcat data_large.txt.gz | head -n #{lines_num} > data.txt"
    work
  end
end
