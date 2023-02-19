#!/usr/bin/env ruby
require_relative 'autoattack'

while MC.current_zone == 'Your Island'
  puts "[t] " + MC.status.dig("sidebar", 3).to_s
  attack_nearest(timeout: 30+rand(30), quiet: true)
  move_a_bit 3
end
