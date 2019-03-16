require './spec/spec_helper'
require_relative './task-2'
require 'benchmark/ips'
require 'ruby-prof'

# RubyProf.measure_mode = RubyProf::ALLOCATIONS
RubyProf.measure_mode = RubyProf::MEMORY

result = RubyProf.profile do
  work('./spec/fixtures/data_medium-10k.txt')
end

# printer = RubyProf::FlatPrinter.new(result)
# printer.print(File.open("ruby_prof_flat_allocations_profile.txt", "w+"))

# printer = RubyProf::DotPrinter.new(result)
# printer.print(File.open("ruby_prof_allocations_profile.dot", "w+"))

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open("ruby_prof_graph_allocations_profile.html", "w+"))

# result = RubyProf.profile do
#   work('./spec/fixtures/data_medium-10k.txt')
# end

# printer = RubyProf::CallTreePrinter.new(result)
# printer.print(:path => ".", :profile => 'profile')
