# frozen_string_literal: true
require_relative '../task-2.rb'
require 'byebug'

INITIAL_DATA_FILE = 'data/data_1mb.txt'
REAL_JSON_FILE_PATH = 'data/report_result.json'

# # TO RECORD SCRIPT EXECUTION
# sudo /usr/local/Cellar/rbspy/0.3.5/bin/rbspy record -- ruby  scripts/rbspy_prof.rb

work(INITIAL_DATA_FILE, REAL_JSON_FILE_PATH)