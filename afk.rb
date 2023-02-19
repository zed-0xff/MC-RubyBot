#!/usr/bin/env ruby
require_relative 'lib/common'

loop do
  move_a_bit
  sleep 60+rand(30)
end
