require_relative './../task-2'
require 'pry'
require 'benchmark'

def prepare_file(file)
  FileUtils.cp file, 'data.txt'
  File.write('result.json', '')
end

def clean
  FileUtils.rm %w[data.txt result.json]
end

def lines_in(file)
  file.sub('./spec/fixtures/data_medium_', '').sub('.txt', '')
end
