# frozen_string_literal: true

require 'ruby-prof'
require_relative '../task-2.rb'
require 'byebug'


RubyProf.measure_mode = RubyProf::WALL_TIME



INITIAL_DATA_FILE = 'data/data_1mb.txt'
REAL_JSON_FILE_PATH = 'data/report_result.json'
OUTPUT_DIR = 'data/profiles/ruby_prof'


def flat_profile
  run_profiler do |result|
    printer = RubyProf::FlatPrinterWithLineNumbers.new(result)
    printer.print(File.open("#{OUTPUT_DIR}/ruby_prof_flat.txt", 'w+'))   
  end
end

def graph_profile
  run_profiler do |result|
    printer = RubyProf::GraphHtmlPrinter.new(result)
    printer.print(File.open("#{OUTPUT_DIR}/ruby_prof_graph.html", "w+"))
  end
end

def callstack_profile
end

def calltree_profile
end


def run_profiler
  RubyProf.measure_mode = RubyProf::WALL_TIME
  result = RubyProf.profile { work(INITIAL_DATA_FILE, REAL_JSON_FILE_PATH) }
  yield result
end

flat_profile
graph_profile