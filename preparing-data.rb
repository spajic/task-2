# frozen_string_literal: true

require 'zlib'

DATA = {
  '1MB' => 1_048_576,
  '4MB' => 4_194_304,
  '10MB' => 10_485_760
}.freeze

DIR = 'data'.freeze

def create_directory
  Dir.mkdir(DIR) unless File.exist?(DIR)
end

def ungz_file
  gz = Zlib::GzipReader.open('data_large.txt.gz')
  unzipped = StringIO.new(gz.read)
  gz.close
  unzipped
end

def create_data(result = ungz_file)
  DATA.each do |name, size|
    result.pos = 0
    copied = 0
    target = File.open("#{DIR}/data_#{name}.txt", 'w+')
    while (line = result.gets)
      break if copied >= size

      target.puts line
      copied += line.size
    end
    target.close
  end
end

create_directory
create_data
