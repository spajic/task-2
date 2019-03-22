require 'benchmark/ips'
require './task-2'

def mac_os?
  RUBY_PLATFORM.match?(/darwin/)
end

def populate(lines_num)
  if mac_os?
    system "zcat < data_large.txt.gz | head -n #{lines_num} > data_#{lines_num}.txt"
  else
    system "zcat data_large.txt.gz | head -n #{lines_num} > data_#{lines_num}.txt"
  end
end

target = 16_000

populate(target)

if File.exist?('ips.result')
  puts "*** Previous result ***"
  system("cat ips.result")
end

puts "*** Result ***"
result = Benchmark.ips do |bench|
  bench.report("Process #{target} lines") do
    work("data_#{target}.txt")
  end
end

_stdout = $stdout
$stdout = StringIO.new
result.entries.each(&:display)
File.open('ips.result', 'w') { |file| file << $stdout.string }
$stdout = _stdout

require './task_test'
