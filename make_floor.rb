#!/usr/bin/env ruby
require_relative 'lib/common'
require_relative 'lib/map'

Y = 1

def build!
  was = false
  map = Map.new
  r = scan(
    offset: { x: 0, y: -1, z: -10 },
    expand: { x: 16, y: 0, z: 6 }
  )
  blocks = r['blocks']
  blocks.each do |block|
    map.put block
  end
  map.put r['player'], 'Z'

  px = r['player']['pos']['x'].round
  pz = r['player']['pos']['z'].round

#  return unless MC.select_tool('INFINIDIRT_WAND')

  map.rz.each do |z|
    next if z == map.rz.begin
    xx = map.rx.begin.upto(px).to_a + map.rx.end.downto(px+1).to_a
    xx.each do |x|
      if map[z-1][x] == 'D' && map[z][x] == nil
        pos = { x: x, y: Y, z: z-1 }
        r = MC.look_at_block!(pos, reach: 25, sides: %w'north', delay: 1)
        if r['lookAtBlock']
          map[z][x] = '✔'
          was = true
          block = r.dig('player', 'looking_at', 'block')
          #next if !block || block['side'] != 'north'

          if block && reachable_block?(block) && MC.player.has_in_hotbar?("DIRT")
            select_tool "DIRT"
            MC.script do
              interact_block! delay_next: 1
              status!
            end
            p player.current_tool
          elsif MC.player.money > 1 && select_tool("INFINIDIRT_WAND")
            MC.interact_item! delay_next: 1
          else
            puts "[!] no dirt nor wand+money".red
            return false
          end
        else
          map[z][x] = '-'
        end
      end
    end
  end

  printf "  %s  rx=%s, rz=%s  px=%.1f pz=%.1f\n\n",
    ("0123456789abcdef"*2)[0, map.rx.size],
    map.rx,
    map.rz,
    r['player']['pos']['x'],
    r['player']['pos']['z']

  puts map.to_s.sub('Z', 'Z'.red)
  was
end

y0 = MC.player.pos.y

loop do
  loop do
    exit if MC.player.pos.y != y0
    break unless build!
  end
  MC.set_pitch_yaw! yaw: -180, delay_next: -1
  15.times do
    MC.travel! :back
  end
end
