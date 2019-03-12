# frozen_string_literal: true

require 'benchmark/ips'
require 'minitest/autorun'
require_relative '../task-2'

class TaskTest < Minitest::Test
  def test_result
    create_report('files/fixtures/data.txt', 'files/fixtures/result.json')

    expected_report = File.read('files/fixtures/expected_report.json')
    actual_report = File.read('files/fixtures/result.json')

    assert_equal expected_report, actual_report
  end

  def teardown
    File.unlink('files/fixtures/result.json')
  end
end

Benchmark.ips do |x|
  x.report('Process 1Mb') { create_report('files/data/data_1_0mb.txt', 'tmp/result.json') }
end
