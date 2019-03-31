require_relative 'task_class'
require 'ruby-prof'
require 'benchmark'

def print_memory_usage
  "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
end

RubyProf.measure_mode = RubyProf::WALL_TIME
result = nil
time = Benchmark.realtime do
  puts  "rss before: #{print_memory_usage}"
  result = RubyProf.profile do
    TaskClass.new.work(filename: ARGV[0])
  end
  puts "rss after: #{print_memory_usage}"
end
puts "Finish in #{time.round(2)}"

printer = RubyProf::FlatPrinter.new(result)
printer.print(File.open("tmp/ruby_prof_flat.txt", "w+"))

# printer2 = RubyProf::GraphHtmlPrinter.new(result)
# printer2.print(File.open("tmp/ruby_prof_graph.html", "w+"))

# printer3 = RubyProf::CallStackPrinter.new(result)
# printer3.print(File.open("tmp/ruby_prof_callstack.html", "w+"))

# printer4 = RubyProf::CallTreePrinter.new(result)
# printer4.print(:path => "tmp/", :profile => 'callgrind')
