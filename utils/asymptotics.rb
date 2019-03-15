# frozen_string_literal: true

require 'benchmark/ips'
require_relative 'prepare_data_chunks'
require_relative '../task-2'

Benchmark.ips do |x|
  SIZE_LIMITS.each do |name, size|
    x.report("Process #{(size / 1_048_576.0).round(1)}Mb") do
      create_report("files/data/#{name}.txt", "tmp/result.json")
    end
  end
  x.compare!
end
