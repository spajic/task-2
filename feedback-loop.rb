require './task-2.rb'
require 'benchmark/ips'
require 'minitest/autorun'

class Test < Minitest::Test
  def setup
    File.write('result.json', '')
  end

  def test_result
    Benchmark.ips do |bench|
      bench.report("Process 1 MB of data") do
        work('data/data_1MB.txt')
      end
    end
  end

  def test_correctness
    work('fixtures/data.txt')
    expected_result = File.read('fixtures/expected_result.json')
    assert_equal expected_result, File.read('result.json')
  end

  def test_time
    result = Benchmark.realtime { work('data/data_1MB.txt') }
    assert(result.round(2) < 0.2)
  end
end
