require './spec/spec_helper'
require_relative './task-2'
require 'benchmark/ips'
require 'ruby-prof'
require 'stackprof'

def start_ruby_prof
  RubyProf.profile do
    work('./spec/fixtures/data_medium-10k.txt')
  end
end

RubyProf.measure_mode = RubyProf::WALL_TIME
result = start_ruby_prof

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open("ruby_prof_flat_allocations_profile.txt", "w+"))
# printer.print(STDOUT)

# printer = RubyProf::DotPrinter.new(result)
# printer.print(File.open("ruby_prof_allocations_profile.dot", "w+"))
#
RubyProf.measure_mode = RubyProf::CPU_TIME
result = start_ruby_prof

printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(File.open("ruby_prof_graph_allocations_profile.html", "w+"), :min_percent => 10)
#
# # printer = RubyProf::CallStackPrinter.new(result)
# # printer.print(File.open("ruby_prof_stack_printer_allocations_profile.sp", "w+"))
#
# RubyProf.measure_mode = RubyProf::MEMORY
# printer = RubyProf::CallTreePrinter.new(result)
# printer.print(:path => ".", :profile => 'profile', :min_percent => 2)


# result = RubyProf.profile do
#   work('./spec/fixtures/data_medium-10k.txt')
# end

# printer = RubyProf::CallTreePrinter.new(result)
# printer.print(:path => ".", :profile => 'profile')


# stackprof

# StackProf.run(mode: :wall, out: 'tmp/stackprof.dump', raw: true) do
#   work('./spec/fixtures/data_medium-10k.txt')
# end
#
# profile_data = StackProf.run(mode: :wall) do
#   work('./spec/fixtures/data_medium-10k.txt')
# end
# #
# # StackProf::Report.new(profile_data).print_text
# # StackProf::Report.new(profile_data).print_method(/make_csv_of_data/)
# StackProf::Report.new(profile_data).print_graphviz
