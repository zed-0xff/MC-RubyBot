#!/usr/bin/env ruby
require_relative 'autoattack'
require_relative 'commissions'

RADIUS = 50
BLOCKTYPES = ARGV
THR = 1.4

if BLOCKTYPES.empty?
  puts "gimme block id(s)"
  exit 1
end

@negatives = Set.new
@prev_time = Time.now - 10

def check_particles
  @pindex ||= 0
  ltick = 0
  loop do
    r = MC.get_particles! prev_index: @pindex
    r['particles'].each do |p|
      @pindex = [p['index'], @pindex].max
      if p['effect'] == 'minecraft:crit'
        MC.chat! "#stop" if ltick == 0
        ltick = [p['tick'], ltick].max
        pos = Pos.new(p['x'], p['y'], p['z'])
        MC.look_at! pos
      end
    end
    break if MC.last_tick - ltick > 50
    sleep 0.5
  end
  ltick != 0
end

def kill_mobs
  mobs = getMobs(reachable: :loose)['mobs'].
    find_all{ |m| is_mob?(m) }
  if mobs.any?
    attack_nearest timeout: 1
  end
end

def enchant!
  if MC.player.inventory.full?
    sleep 0.1
    begin
      enchant_inventory!
    rescue => e
      puts "[!] #{e}".red
      sleep 1
      return
    ensure
      MC.close_screen!
    end
    sleep 0.2
    # prevent not mining after enchant
    MC.press_key! 'key.mouse.left'
    sleep 0.05
    MC.release_key! 'key.mouse.left'
  end
end

@last_sound_index = 0

HIT_SOUNDS = %w'minecraft:block.stone.hit minecraft:block.glass.hit'

def wait_for_silence nticks
  last_stone_hit_tick = nil
  t0 = MC.last_tick
  while last_stone_hit_tick.nil? || (MC.last_tick - last_stone_hit_tick < nticks)
    check_particles
    sounds = MC.get_sounds!(prev_index: @last_sound_index)['sounds']
    if sounds.any?
      l = sounds.find_all{ |s| HIT_SOUNDS.include?(s['id']) }.map{ |s| s['tick'] }.max
      last_stone_hit_tick = l if l
      last_sound = sounds.sort_by{ |s| s['index'] }.last
      @last_sound_index = last_sound['index']
    end
    sleep 0.1
    break if last_stone_hit_tick.nil? && MC.last_tick - t0 > nticks
  end
end

def go axis, dir, bpos
  case [axis, dir]
  when [:x, -1]
    MC.set_pitch_yaw! yaw: +90, pitch: 0
  when [:x, +1]
    MC.set_pitch_yaw! yaw: -90, pitch: 0
  when [:z, -1]
    MC.set_pitch_yaw! yaw: 180, pitch: 0
  when [:z, +1]
    MC.set_pitch_yaw! yaw: 0, pitch: 0
  else
    raise
  end
  sleep 0.1

#  loop do
#    MC.press_key! 'w'
#    while (bpos.send(axis) <=> MC.player.pos.send(axis).to_i) == dir
#      pos0 = MC.player.pos
#      sleep 0.1
#      break if MC.player.pos == pos0
#    end
#    MC.release_key! 'w'
#    return if (MC.player.pos.send(axis) - bpos.send(axis)).abs < THR
#
#    l = (MC.player.pos.send(axis).to_i - bpos.send(axis)).abs + 2
#    MC.chat! "#tunnel 2 2 #{l}"
#    sleep 1
#    wait_for_silence 30
#    puts "[d] tunneling done"
#    MC.chat! "#stop"
#    break
#  end

  MC.chat! "#tunnel 2 1 100"
  sleep 0.01
  MC.invalidate_cache!
  poss = []
  while (bpos.send(axis) <=> MC.player.pos.send(axis).to_i) == dir
    break if MC.current_map != "Crystal Hollows"
    break if check_particles
    break if respect_player
    poss << MC.player.pos
    if poss.size > 20
      poss.shift
      if poss.uniq.size == 1
        puts "[?] stuck".yellow
        MC.chat! "#stop"
        if false && MC.player.dig('looking_at', 'block', 'id').to_s =~ /_glass/
          MC.chat! "#tunnel 2 5 5"
          sleep 5
        else
          key = %w'w s a d'.random
          MC.press_key! key
          sleep 1
          MC.release_key! key
          break
        end
      end
    end
    sleep 0.2
  end
  MC.chat! "#stop"
end

def dig_to b
  bpos = Pos[b['pos']]
  puts "[.] #{MC.player.pos.to_a.map(&:to_i)} -> #{bpos.to_a}"
  #MC.look_at! bpos
  MC.chat! "#goal #{bpos.to_a.join(' ')}"

  loop do
    if MC.player.pos.x - bpos.x > THR
      go :x, -1, bpos
    elsif bpos.x - MC.player.pos.x > THR
      go :x, +1, bpos
    elsif MC.player.pos.z - bpos.z > THR
      go :z, -1, bpos
    elsif bpos.z - MC.player.pos.z > THR
      go :z, +1, bpos
    elsif MC.player.pos.y - bpos.y > THR
      y = 0
      while MC.player.pos.y - bpos.y > THR
        MC.set_pitch_yaw! pitch: 80, yaw: y
        sleep 0.4
        y += 90
      end
    else
      gather_near
      return true
    end
  end
end

MC.chat! "#stop"
#auto_jump true

begin
  while MC.current_map == "Crystal Hollows"
    if MC.player.inventory.full?
      MC.chat! "#stop"
      enchant!
    end
    if commissions.values.include?("DONE")
      MC.chat! "#stop"
      call_emissary
    end
    MC.chat!("#mine " + BLOCKTYPES.join(" ")) if MC.player.speed == 0
    sleep 5
  end
rescue Interrupt
end

MC.chat! "#stop"
auto_jump false
