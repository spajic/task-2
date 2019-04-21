def save_stdout_to_file(filename)
  $stdout = StringIO.new

  yield

  $stdout.rewind

  File.open("#{$optimizations_dir}/#{filename}", 'w') { |f| f.write($stdout.read) }
end