#!/bin/sh

echo "Start RSpec"
rspec ./spec/smoke_test_spec.rb
echo "Start benchmark\n"
ruby tools/calc_times.rb
