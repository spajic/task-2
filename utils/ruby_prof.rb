# frozen_string_literal: true

require 'ruby-prof'
require_relative '../task-2'

OUTPUT_DIR = 'tmp/ruby_prof'

def flat_report
  run_profile do |profile|
    RubyProf::FlatPrinter.new(profile).print(STDOUT)
  end
end

def graph_report
  run_profile do |profile|
    printer = RubyProf::GraphHtmlPrinter.new(profile)
    File.open("#{OUTPUT_DIR}/graph_report.html", 'w') { |f| printer.print(f) }
  end
end

def call_stack_report
  run_profile do |profile|
    printer = RubyProf::CallStackPrinter.new(profile)
    File.open("#{OUTPUT_DIR}/stack_report.html", 'w') { |f| printer.print(f) }
  end
end

def call_tree_report
  run_profile do |profile|
    RubyProf::CallTreePrinter.new(profile).print(path: OUTPUT_DIR, profile: 'profile')
  end
end

def run_profile(mode: RubyProf::WALL_TIME)
  RubyProf.measure_mode = mode

  profile = RubyProf.profile { create_report('files/data/data_1_0mb.txt', 'tmp/result.json') }

  yield profile
end
