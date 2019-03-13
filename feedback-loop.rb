require 'benchmark/ips'
require './task-2.rb'

def reevaluate_metric
  Benchmark.ips do |bench|
    bench.report('Process 1 MB of data') do
      work('data/data_1mb.txt')
    end
  end
end

def test_correctness
  File.write('result.json', '')
  work('fixtures/data_fixture.txt')
  expected_result = File.read('fixtures/expected_result_fixture.json')
  passed = expected_result == File.read('result.json')
  passed ? puts('PASSED') : puts('!!! TEST FAILED !!!')
end

reevaluate_metric
test_correctness
