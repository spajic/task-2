# frozen_string_literal: true

FILES = {
  "512Kb" => 524_268,
  "1Mb" => 1_048_576,
  "2Mb" => 2_097_152,
  "4Mb" => 4_194_304,
  "8Mb" => 8_388_608,
}.freeze

FILES.each do |name, size|
  copied = 0
  source = File.open("data_large.txt")
  target = File.open("data_#{name}", "w+")
  while (line = source.gets)
    break if copied >= size
    target.puts line
    copied += line.size
  end
ensure
  source.close
  target.close
end
