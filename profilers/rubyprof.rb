require 'ruby-prof'
require_relative '../task-2'

def profile(mode:)
  puts "*** Measure mode #{mode} ***"

  RubyProf.measure_mode = Object.const_get("RubyProf::#{mode.upcase}")

  result = RubyProf.profile do
    work('data_16000.txt')
  end

  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT)
end

profile(mode: ENV['RUBYPROF_MODE'])
