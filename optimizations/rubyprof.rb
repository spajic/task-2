require_relative '../lib/parser'
require_relative '../spec/stdout_to_file'
require 'ruby-prof'

GC.disable

save_stdout_to_file('rubyprof_wall.txt') do
  RubyProf.measure_mode = RubyProf::WALL_TIME

  result = RubyProf.profile do
    work('data_65kb.txt')
  end

  printer = RubyProf::FlatPrinter.new(result)
  printer.print($stdout)
end

GC.enable

save_stdout_to_file('rubyprof_alloc.txt') do
  RubyProf.measure_mode = RubyProf::ALLOCATIONS

  result = RubyProf.profile do
    work('data_65kb.txt')
  end

  printer = RubyProf::FlatPrinter.new(result)
  printer.print($stdout)
end