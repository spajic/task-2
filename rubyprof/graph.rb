require 'ruby-prof'
require_relative '../task-2'

RubyProf.measure_mode = RubyProf::WALL_TIME

result = RubyProf.profile do
  work('data_16000.txt')
end

GC.disable
printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open("rubyprof/graph.html", "w+"))
