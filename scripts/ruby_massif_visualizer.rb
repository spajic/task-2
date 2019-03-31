# frozen_string_literal: true

require_relative "../task-2.rb"
require "byebug"
# valgrind --tool=massif `rbenv which ruby` scripts/ruby_massif_visualizer.rb

INITIAL_DATA_FILE = "data/data_large.txt"
REAL_JSON_FILE_PATH = "data/report_result.json"

work(INITIAL_DATA_FILE, REAL_JSON_FILE_PATH, progress: false)