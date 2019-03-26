require 'minitest/spec'
require 'minitest/autorun'
require 'benchmark'

require_relative '../task-2.rb'

class TestMe < Minitest::Test
  REAL_JSON_FILE_PATH = 'data/report_result.json'
  
  def test_result
    initial_data_file = 'data/test_data/data.txt'
    expected_report_file_path = 'data/test_data/expected_result.json'
    
    work(initial_data_file, REAL_JSON_FILE_PATH)
    expected_report_result = File.read(expected_report_file_path)
    real_report_result = File.read(REAL_JSON_FILE_PATH)
 
    assert_equal(expected_report_result, real_report_result)
  end

  def test_time

    time = Benchmark.realtime { work('data/data_1mb.txt', 'data/test_data/outcome_time') }
    assert(time.round(2) <= 0.3)
  end
end
