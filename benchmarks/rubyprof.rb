require './task-2.rb'
require 'ruby-prof'

RubyProf.measure_mode = RubyProf::MEMORY

result = RubyProf.profile do
  work('data/data_125k.txt')
end

printer = RubyProf::CallTreePrinter.new(result)
printer.print(:path => "tmp", :profile => 'profile')
