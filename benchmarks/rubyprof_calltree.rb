require './task-2.rb'
require 'ruby-prof'

# stackprof tmp/stackprof.dump --text --limit 5
RubyProf.measure_mode = RubyProf::MEMORY

result = RubyProf.profile do
  work('data/data_500k.txt')
end

printer = RubyProf::CallTreePrinter.new(result)
printer.print(:path => "tmp", :profile => 'calltree')
