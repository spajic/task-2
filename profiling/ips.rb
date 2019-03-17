ENV["NOPROGRESS"] = '1'
require_relative '../lib/task-1.rb'
require 'benchmark/ips'

FILES = {
  "512Kb" => 524_268,
  "1Mb" => 1_048_576,
  "2Mb" => 2_097_152,
  "4Mb" => 4_194_304,
  "8Mb" => 8_388_608,
}.freeze

class GCSuite
  def warming(*)
    run_gc
  end

  def running(*)
    run_gc
  end

  def warmup_stats(*)
  end

  def add_report(*)
  end

  private

  def run_gc
    GC.enable
    GC.start
    GC.disable
  end
end


suite = GCSuite.new

Benchmark.ips do |x|
  x.config(suite: suite, stats: :bootstrap, confidence: 99)
  FILES.keys.each do |size|
    x.report("File: #{size}") { work(input: "../samples/data_#{size}", output: "/dev/null") }
  end
  x.compare!
end
