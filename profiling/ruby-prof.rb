ENV["NOPROGRESS"] = '1'

require_relative '../lib/task-1.rb'
require 'ruby-prof'

RubyProf.measure_mode = RubyProf::CPU_TIME
result = RubyProf.profile do
  work(input: "../samples/data_4Mb", output: "/dev/null")
end

printer = RubyProf::MultiPrinter.new(result)
printer2 = RubyProf::CallTreePrinter.new(result)
printer.print(path: "./results", profile: "task-1")
printer2.print(path: "./results", profile: "task-1_calltree")
