# frozen_string_literal: true

SIZE_LIMITS = {
  data_0_5mb: 524_288,
  data_1_0mb: 1_048_576,
  data_1_5mb: 1_572_864,
  data_2_0mb: 2_097_152,
  data_2_5mb: 2_621_440,
  data_3_0mb: 3_145_728,
  data_3_5mb: 3_670_016,
  data_4_0mb: 4_194_304,
  data_4_5mb: 4_718_592,
  data_5_0mb: 5_242_880
}.freeze

def prepare_data_chunks(source_file)
  File.open(source_file, 'r') do |source|
    SIZE_LIMITS.each do |filename, limit|
      slice_data_to_file(filename, source, limit)
    end
  end
end

def slice_data_to_file(target_filename, data, limit)
  size_in_bytes = 0
  File.open("files/data/#{target_filename}.txt", 'w') do |target|
    data.each_line do |line|
      size_in_bytes += line.length
      break if size_in_bytes >= limit

      target.puts line
    end
  end
end


prepare_data_chunks('files/data/data_large.txt')

