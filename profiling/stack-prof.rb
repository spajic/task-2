ENV["NOPROGRESS"] = '1'

require_relative '../lib/task-1.rb'
require 'stackprof'

mode = ENV["MODE"] || :wall

StackProf.run(mode: mode.to_sym, out: "./results/stackprof.dump") do
  work(input: "../samples/data_4Mb", output: "/dev/null")
end
