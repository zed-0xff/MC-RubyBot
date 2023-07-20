#!/usr/bin/env ruby
require_relative 'lib/common'
require_relative 'enchant'

loop do
  enchant_inventory! if MC.player.inventory.full?

  while MC.player.dig('looking_at', 'block', 'id') == "minecraft:cocoa"
    sleep 0.1
    MC.invalidate_cache!
  end

  MC.travel! :forward, amount: 0.6

  z = MC.player.pos.z
  if z < 51 || z >= 140
    r = scan
    r['blocks'].each do |b|
      if b['id'] == 'minecraft:cocoa' && b['age'] == 2
        ai_move_to Pos.new(b['pos']['x'], MC.player.pos.y, b['pos']['z'])
        if MC.player.yaw.abs < 90
          MC.set_pitch_yaw! pitch: -34.5, yaw: 0
        else
          MC.set_pitch_yaw! pitch: -34.5, yaw: 180
        end
        break
      end
    end
  end
end
