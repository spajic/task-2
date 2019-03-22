require 'minitest/autorun'
require 'benchmark/ips'

class WorkBenchmark < Minitest::Test
  BEST_IPS_RESULT = 16.537.freeze
  ERROR_IPS_RESULT = 0.15.freeze
  TOP_ALLOCATED_MEMORY = 10.freeze
  ERROR_ALLOCATED_MEMORY = 3.freeze

  def test_benchmark
    actual =
      Benchmark.ips do |bench|
        bench.report("Process 0.25 MB of data") do
          work('data/data_large.025.txt')
        end
      end
    actual = actual.data.first[:ips].round(3)

    assert actual >= BEST_IPS_RESULT - ERROR_IPS_RESULT
  end

  def test_memory
    before = `ps -o rss= -p #{Process.pid}`.to_i
    work("data/data_large.025.txt")
    after = `ps -o rss= -p #{Process.pid}`.to_i
    puts "Memory usage: #{result = (after - before) / 1024} MB"

    assert result <= TOP_ALLOCATED_MEMORY + ERROR_ALLOCATED_MEMORY
  end
end