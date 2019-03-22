require 'ruby-prof'
require_relative '../task-2'

RubyProf.measure_mode = RubyProf::WALL_TIME

result = RubyProf.profile do
  work('data_16000.txt')
end

GC.disable
printer = RubyProf::CallTreePrinter.new(result)
printer.print(path: "./rubyprof", profile: "callgrind")
