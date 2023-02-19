#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'autoattack'
require_relative 'enchant'
#require_relative 'fish'
require_relative 'farm_mobs'

SCAN_RANGE = 23
SHOOT_RANGE = 12

def gather_near
  r = MC.blocks!
  blocks = r['blocks']

  lilypads = blocks.
    find_all{ |b| b['id'] == 'minecraft:lily_pad' }.
    sort_by{ |b| distance(b['pos']) }

  #puts "[.] #{lilypads.size} near lilypads"

  lilypads.each do |lp|
    r = MC.look_at_block! lp['pos']
    #p r.dig('player', 'looking_at')
    sleep 0.1
  end
  lilypads.size
end

def gather_far
  r = MC.blocks! radius: SCAN_RANGE, radiusY: 6
  blocks = r['blocks']

  lilypads = blocks.
    find_all{ |b| b['id'] == 'minecraft:lily_pad' }.
    sort_by{ |b| distance(b['pos']) }

  #puts "[.] #{lilypads.size} far lilypads"

  lilypads.each do |lp|
    if distance(lp['pos']) < BLOCK_REACHABLE_DISTANCE
      MC.look_at_block! lp['pos']
    else
      MC.look_at! lp['pos']
    end
    MC.chat!("#goto " + lp['pos'].values.map(&:to_s).join(" "), quiet: true)
    sleep 1
    wait_for(max_wait: 5, raise: false) do
      r = MC.look_at! lp['pos']
      m = MC.player.dig('nbt', 'Motion')
      (r.dig('player', 'looking_at', 'block', 'id') == 'minecraft:lily_pad') ||
        (m[0] == 0 && m[2] == 0)
    end
    MC.chat!("#stop", quiet: true)
    break
  end
  lilypads.size
end

def shoot_mobs!
  n = 0
  getMobs(radius: SHOOT_RANGE, radiusY: 5)['entities'].each do |mob|
    #printf "[*] %5.1f %s\n", distance(mob['pos']), shortstatus(mob)
    next if mob['pos']['y'] > MC.player.pos.y
    next if rand() < 0.15
#    r = MC.raytrace! range: (distance(mob['pos'])-0.2), liquids: false
#    next if r.dig('raytrace', 'block')
#    if r.dig('raytrace', 'entity', 'id') != "minecraft:slime"
#      p r.dig('raytrace')
#      next
#    end
    #next if r.dig('raytrace', 'entity', 'id') != "minecraft:slime"
    n += 1
    with_tool("PRISMARINE_BOW", select_previous: false) do
      sleep 0.05
      MC.look_at!(mob['eyePos'])
      MC.press_key! 'key.mouse.right'
      sleep 1.5
      r = MC.get_entity! uuid: mob['uuid']
      if (mob = r['entity'])
        MC.look_at!(Pos[mob['eyePos']] + Pos[0, 0.5, 0])
      end
      MC.release_key! 'key.mouse.right'
      sleep 0.1
    end
    with_tool("LIVID_DAGGER", select_previous: false) do
      sleep 0.05
      MC.look_at!(mob['eyePos'])
      MC.interact_item!
      sleep 0.1
      return n
    end
  end
  n
end

def count!
  unless @tstart
    @tstart = Time.now
    @c0 = MC.player.inventory.count("ENCHANTED_WATER_LILY")*160 + MC.player.inventory.count("WATER_LILY")
    @t0 = Time.now
    return
  end
  t1 = Time.now
  if t1-@t0 >= 60
    c1 = MC.player.inventory.count("ENCHANTED_WATER_LILY")*160 + MC.player.inventory.count("WATER_LILY")

    dt = t1 - @tstart
    formatted_dt = "%02d:%02d" % [dt/3600, (dt/60)%60]
    printf "[.] %s %2ds, %3d items/min\n", formatted_dt, (t1-@t0), (c1-@c0)/(t1-@t0)*60

    @c0 = c1
    @t0 = t1
  end
end

def enchant!
  if MC.player.inventory.full?
    enchant_inventory!
    true
  else
    false
  end
end

def farm_lilypads
  while MC.current_map == "Crystal Hollows"
    count!
    n = 0
    n += gather_near
    n += gather_far
    n += gather_near
    n += shoot_mobs! if rand() < 0.75
    sleep 0.05
    if n == 0
      enchant!
      puts "[.] idling.."
      MC.chat! "#wp goto t1"
      sleep 5
      #fish!(look_at_water: false) rescue nil
      farm_mobs
      sleep 5 + rand(5)
    end
    sleep 0.1
  end
end

if $0 == __FILE__
  farm_lilypads
end
