require_relative '../lib/parser'
require_relative '../spec/stdout_to_file'
require 'stackprof'

GC.disable

save_stdout_to_file('stackprof_wall.txt') do
  profile_Data = StackProf.run(mode: :wall) do
    work('data_65kb.txt')
  end

  StackProf::Report.new(profile_Data).print_text(nil, nil, nil, nil, nil, nil, $stdout)
  StackProf::Report.new(profile_Data).print_method('Object#work', $stdout)
end

GC.enable

save_stdout_to_file('stackprof_object.txt') do
  profile_Data = StackProf.run(mode: :object) do
    work('data_65kb.txt')
  end

  StackProf::Report.new(profile_Data).print_text(nil, nil, nil, nil, nil, nil, $stdout)
  StackProf::Report.new(profile_Data).print_method('Object#work', $stdout)
end