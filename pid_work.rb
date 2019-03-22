require './task-2'

GC.disable
puts Process.pid
work(ENV['DATA'] || 'test_16000.txt')
