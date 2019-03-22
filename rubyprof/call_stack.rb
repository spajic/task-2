require 'ruby-prof'
require_relative '../task-2'

RubyProf.measure_mode = RubyProf::WALL_TIME

result = RubyProf.profile do
  work('data_16000.txt')
end

GC.disable
printer = RubyProf::CallStackPrinter.new(result)
printer.print(File.open("rubyprof/call_stack_#{Time.now.to_i}.html", "w+"))
