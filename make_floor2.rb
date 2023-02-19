#!/usr/bin/env ruby
require_relative 'lib/common'
require_relative 'lib/map'

Y = 1

def build!
  z0 = (MC.player.pos.z).round
  r = scan(
    offset: { x: 14, y: -1, z: 0 },
    expand: { x: 8,  y: 1, z: 1 }
  )

  min_x = r['blocks'].
    delete_if { |block| block['pos']['z'] != z0 }.
    map { |block| block['pos']['x'] }.
    min 

  if min_x.nil?
    p r['blocks']
    raise "min_x is NULL"
  end

  r = MC.script do
    look_at!(Pos[min_x, 1, z0] + Pos[0, 0.05, 0.5])
    status!
  end

  if (side = r.dig('player', 'looking_at', 'block', 'side'))
    if side == 'up'
      sleep 0.2
      r = MC.look_at!(Pos[min_x, 1, z0] + Pos[0, 0.05, 0.5])
      side = r.dig('player', 'looking_at', 'block', 'side')
    end
    return false if side != 'west'
  end

  pos = r.dig('player', 'looking_at', 'block', 'pos')
  return false if pos && pos['y'] != 1

  if MC.player.money > 1 && select_tool("INFINIDIRT_WAND")
    tick0 = MC.last_tick
    MC.interact_item! delay_next: 1
    wait_for { MC.get_sounds!['sounds'].find{ |s| s['id'] == 'minecraft:block.grass.break' && s['tick'] > tick0 } }
    return true
  else
    puts "[!] no dirt nor wand+money".red
  end
  false
end

y0 = MC.player.pos.y

loop do
  exit if MC.player.pos.y != y0
  while build! do
  end
  z0 = MC.player.pos.z.to_i
  MC.set_pitch_yaw! yaw: -90
  MC.travel! :right
  sleep 0.1
  MC.invalidate_cache!
end
