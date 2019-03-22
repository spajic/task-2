require './task-2.rb'
require 'stackprof'

# stackprof tmp/stackprof.dump --text --limit 5
GC.disable
StackProf.run(mode: :wall, out: './tmp/stackprof.dump', raw: true) do
  work('data/data_125k.txt')
end
