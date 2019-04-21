require_relative '../lib/parser'
require 'ruby-prof'

RubyProf.measure_mode = RubyProf::MEMORY

result = RubyProf.profile do
  work('data_65kb.txt')
end

printer = RubyProf::CallTreePrinter.new(result)
printer.print(path: "#{$optimizations_dir}", profile: 'profile')