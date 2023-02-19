#!/usr/bin/env ruby
require_relative 'farm_mobs'

loop do
  while MC.current_map != 'Dwarven Mines'
    MC.chat! "/warp forge"
    sleep 5
    MC.invalidate_cache!
  end

  while MC.current_zone != "Great Ice Wall"
    if MC.player.speed == 0
      MC.chat! "#wp goto great_ice_wall"
      sleep 5
    end
    sleep 1
    MC.invalidate_cache!
  end

  farm_mobs filter: /Ice/
end
