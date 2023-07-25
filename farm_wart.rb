#!/usr/bin/env ruby
require_relative 'enchant'

PLOT_NAME = "Wart"
START_X = -236.5
START_Y = 71
START_Z = 44.5
END_Z   = -45.5

if $0 == __FILE__
  loop do
    if MC.current_map != "Garden"
      MC.chat! "/warp garden"
      wait_for { MC.current_map == "Garden" }
    end

    farm_prepared2!(
      start_x: START_X, start_y: START_Y, start_z: START_Z,
      end_z: END_Z, name: PLOT_NAME,
      rowsize: 11, nrows: 9, pitch: 0
    )
    break if ARGV.include?('--oneshot')
  end
end
