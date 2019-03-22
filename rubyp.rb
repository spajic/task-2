require 'ruby-prof'
require './task-2.rb'

RubyProf.measure_mode = RubyProf::WALL_TIME

result = RubyProf.profile do
  work('data/data_1MB.txt', disable_gc: true)
end

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open('ruby_prof_flat.txt', 'w+'))

# printer2 = RubyProf::GraphHtmlPrinter.new(result)
# printer2.print(File.open('ruby_prof_graph.html', 'w+'))
#
# printer3 = RubyProf::CallStackPrinter.new(result)
# printer3.print(File.open('ruby_prof_callstack.html', 'w+'))

# printer4 = RubyProf::CallTreePrinter.new(result)
# printer4.print(:path => ".", :profile => 'callgrind')
