#!/usr/bin/env ruby
require_relative 'autoattack'
require_relative 'enchant'

MC.cache_ttl = 0.1

#x: 123.5 .. 135.5

points = [
  Pos[ 10, 149,  -95],
  Pos[  7, 149, -100],
  Pos[ -5, 149, -101],
  Pos[-10, 149,  -93],
  Pos[-10, 149,  -74],
  Pos[ -5, 149,  -69],
  Pos[  6, 149,  -69],
  Pos[ 11, 149,  -74],
]

stripes = []

while player.inventory.has_free_slots? && MC.current_zone == "Dwarven Mines"
  select_slot 3 # FIXME!
  points.each do |dst|
    p dst
#    loop do
#      t = Pos[rand()-0.5, 0, rand()-0.5]
#      next if stripes.include?((dst+t).x.to_i)
#      dst += t
#      break
#    end
    look_at dst
    set_pitch_yaw pitch: 32+rand(10)
    press_key 'w'
    while (distance(dst) > 0.5) && MC.current_zone == "Dwarven Mines"
      break if respect_player
      if ["minecraft:bedrock", "minecraft:polished_andesite"].include?( player.dig('looking_at', 'block', 'id') )
        if rand(2) == 1
          press_key 'a', 80+rand(40)
        else
          press_key 'd', 80+rand(40)
        end
      else
        sleep 0.1
      end
    end
    release_key 'w'
  end
end
