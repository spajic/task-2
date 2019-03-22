require './task-2'
require 'ruby-prof'

# stackprof tmp/stackprof.dump --text --limit 5
GC.enable_stats
RubyProf.measure_mode = RubyProf::MEMORY

result = RubyProf.profile do
  work('data/data_large.05.txt')
end

printer = RubyProf::CallTreePrinter.new(result)
printer.print(:path => "tmp", :profile => 'profile')