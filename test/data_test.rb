require 'minitest/autorun'
require 'benchmark'
require './task-2.rb'

class TestMe < Minitest::Test
  def setup
    File.write('result.json', '')
  end

  def test_result
    work('test/fixtures/data.txt')
    assert_equal File.read('test/fixtures/expected_result.json'), File.read('tmp/result.json')
  end

  def test_time
    time = Benchmark.realtime { work('data/data_1m.txt') }.round(2)
    p "Time: #{time}"
    assert_operator(time, :<, 0.2)
  end

  def test_memory
    work('data/data_1m.txt')
    mem_after = memory_usage.round(2)
    p "Mem: #{mem_after}"
    assert_operator(mem_after, :<, 50)
  end

  def memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i / 1024
  end
end
