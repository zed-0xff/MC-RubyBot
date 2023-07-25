#!/usr/bin/env ruby
require_relative 'enchant'

PLOT_NAME = "Carrot"
START_X = 55.5
START_Y = 70
START_Z = -49.5
END_Z   = -142.5

if $0 == __FILE__
  loop do
    if MC.current_map != "Garden"
      MC.chat! "/warp garden"
      wait_for { MC.current_map == "Garden" }
    end

    farm_prepared2!(
      start_x: START_X, start_y: START_Y, start_z: START_Z,
      end_z: END_Z, name: PLOT_NAME
    )
    farm_prepared2!(
      start_x: 136.5, start_y: START_Y, start_z: START_Z,
      end_z: END_Z, name: PLOT_NAME,
      reverse: true, yaw: 90
    )
    break if ARGV.include?('--oneshot')
  end
end
