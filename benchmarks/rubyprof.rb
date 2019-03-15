require './task-2.rb'
require 'ruby-prof'

RubyProf.measure_mode = RubyProf::Memory

result = RubyProf.profile do
  work('data/data_250k.txt', disable_gc: true)
end

# printer = RubyProf::FlatPrinter.new(result)
# printer.print(File.open("tmp/ruby_prof_flat.txt", "w+"))

# printer2 = RubyProf::GraphHtmlPrinter.new(result)
# printer2.print(File.open("ruby_prof_graph.html", "w+"))

printer3 = RubyProf::CallStackPrinter.new(result)
printer3.print(File.open("tmp/ruby_prof_callstack.html", "w+"))
