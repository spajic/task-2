# frozen_string_literal: true

require 'benchmark'
require 'benchmark/ips'
require 'minitest/autorun'
require_relative '../task-2'

TMP_RESULT_FILE = 'tmp/result.json'

class TaskTest < Minitest::Test
  def test_result
    report('files/fixtures/data.txt')

    expected_report = File.read('files/fixtures/expected_report.json')
    actual_report = File.read(TMP_RESULT_FILE)

    assert_equal expected_report, actual_report
  end

  def test_execution_time
    time = Benchmark.realtime { report('files/data/data_1_0mb.txt') }
    assert time < 0.3
  end

  def teardown
    File.unlink(TMP_RESULT_FILE)
  end

  private

  def report(source_file)
    create_report(source_file, TMP_RESULT_FILE)
  end
end

Benchmark.ips do |x|
  x.report('Process 1Mb') { create_report('files/data/data_1_0mb.txt', TMP_RESULT_FILE) }
end
