#!/bin/bash

valgrind --tool=massif --massif-out-file=./massif.out ruby massif.rb && \
massif-visualizer massif.out
