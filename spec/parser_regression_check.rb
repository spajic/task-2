require_relative '../lib/parser'
require 'benchmark/ips'
require 'yaml'

metrics, = Benchmark.ips do |bench|
  bench.config(warmup: 2, time: 2)

  bench.report { work('data_65kb.txt') }
end.data

stored_metrics = YAML.load_file("#{$support_dir}/regression_metrics.yml")

if stored_metrics[:ips] > metrics[:ips]
  p "Regression - Was: #{stored_metrics[:ips]}, Became: #{metrics[:ips]}"
else
  File.write("#{$support_dir}/regression_metrics.yml", { ips: metrics[:ips].round(2) }.to_yaml)
  p "Progression - Was: #{stored_metrics[:ips]}, Became: #{metrics[:ips]}"
end
