#!/usr/bin/env ruby
require_relative 'autoattack'
require_relative 'commissions'

RADIUS = 50
BLOCKTYPES =
  if ARGV.any?
    ARGV
  else
    %w'
      chest
      diamond_ore
      lime_stained_glass lime_stained_glass_pane
      #red_stained_glass #red_stained_glass_pane
      orange_stained_glass orange_stained_glass_pane
      purple_stained_glass purple_stained_glass_pane
      prismarine_bricks prismarine dark_prismarine light_blue_wool
      light_blue_stained_glass light_blue_stained_glass_pane
      blue_stained_glass blue_stained_glass_pane
      yellow_stained_glass yellow_stained_glass_pane
    '
  end

THR = 1.4

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

def gather_near
  check_particles
  r = MC.blocks!
  blocks = r['blocks']

  ores = blocks.
    find_all{ |b| BLOCKTYPES.any?{ |bt| b['id'][bt] } }.
    find_all{ |b| distance(b['pos']) < 4.2 }.
    sort_by do |b|
      stand_on = Pos[b['pos']] == (MC.player.block_pos + Pos[0,-1,0])
      # mine stand-on block last
      # mine topmost first
      (stand_on ? 10000 : 0) - b['pos']['y']
    end

  #p ores.map{ |b| b['pos'] }

  was = false
  ores[0,5].each do |b|
    check_particles
    respect_player
    enchant!
    printf "[.] %3.1f  %s\n", distance(b['pos']), b['id'].sub('minecraft:','')
    #stop!
    10.times do
      r = MC.look_at!(Pos[b['pos']] + Pos[0.5, 0.5, 0.5]).dig('player', 'looking_at', 'block')
      break if r.nil?
      #break if r['id'] =~ /yellow_stained/
      break if r['id'] == 'minecraft:bedrock'
      case r['id']
      when /prismarine/
        sleep 1
      when /block/
        sleep 0.7
        # better check pickaxe speed
        sleep 0.3 if MC.player.ironman? || MC.player.bingo?
      when /glass/
        sleep 3
      else
        sleep 0.15
      end
      if r['pos'] == b['pos']
        sleep 0.15
        break
      end
    end
  end
  kill_mobs
  was
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
  gather_near
  oy = 0
  while MC.current_map == "Crystal Hollows"
    call_emissary if commissions.values.include?("DONE")
    #p MC.messages!['messages']
    blocks = []
    BLOCKTYPES.each do |bt|
      r = MC.blocks!( radius: RADIUS, radiusY: 2, offset: {x: 0, y: oy, z: 0}, filter: "minecraft:#{bt}" )['blocks']
      blocks.append(*r) if r
    end
    if blocks.empty?
      oy -= 1
      redo
    end
    blocks.sort_by!{ |b| distance(b['pos']) }
    printf "[.] found %d blocks\n", blocks.size
    b = blocks.first
    dig_to(b)
  end
rescue Interrupt
end

MC.chat! "#stop"
auto_jump false
