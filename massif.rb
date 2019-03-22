# valgrind --tool=massif `ruby` massif.rb
require './task-2.rb'

GC.disable
work('data/data_large.05.txt')