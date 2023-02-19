#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'autoattack'
require_relative 'enchant'
#require_relative 'fish'

SCAN_RANGE = 22
SHOOT_RANGE = 12

def gather_near
  r = MC.blocks!
  blocks = r['blocks']

  gravel = blocks.
    find_all{ |b| b['id'] == 'minecraft:gravel' }.
    sort_by{ |b| distance(b['pos']) }

  #puts "[.] #{gravel.size} near gravel"

  gravel.each do |lp|
    r = MC.look_at_block! lp['pos']
    #p r.dig('player', 'looking_at')
    sleep 0.1
  end
  gravel.size
end

@last_gotos = []

def gather_far
  r = MC.blocks! radius: SCAN_RANGE, radiusY: 5
  blocks = r['blocks']

  gravel = blocks.
    find_all{ |b| b['id'] == 'minecraft:gravel' }.
    sort_by{ |b| distance(b['pos']) }

  #puts "[.] #{gravel.size} far gravel"

  gravel.each do |lp|
    next if lp['pos']['x'] in -202..-201

    if distance(lp['pos']) < BLOCK_REACHABLE_DISTANCE
      MC.look_at_block! lp['pos']
    else
      MC.look_at! lp['pos']
    end

    next if @last_gotos.include?(lp['pos'])
    @last_gotos << lp['pos']
    @last_gotos.pop if @last_gotos.size > 15

    pos0 = MC.player.pos
    MC.chat!("#goto " + lp['pos'].values.map(&:to_s).join(" "), quiet: true)
    sleep 1
    wait_for(max_wait: 5, raise: false) do
      r = MC.look_at! lp['pos']
      m = MC.player.dig('nbt', 'Motion')
      (r.dig('player', 'looking_at', 'block', 'id') == 'minecraft:gravel') ||
        (m[0] == 0 && m[2] == 0)
    end
    MC.chat!("#stop", quiet: true)
    pos1 = MC.player.pos
    break if pos0 != pos1
  end
  gravel.size
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
      look_at(mob['eyePos'])
      MC.press_key! 'key.mouse.right'
      sleep 1.5
      r = MC.get_entity! uuid: mob['uuid']
      if (mob = r['entity'])
        look_at(Pos[mob['eyePos']] + Pos[0, 0.5, 0])
      end
      MC.release_key! 'key.mouse.right'
      sleep 0.1
    end
  end
  n
end

def count!
  unless @tstart
    @tstart = Time.now
    @c0 = MC.player.inventory.count("ENCHANTED_FLINT")*160 + MC.player.inventory.count("FLINT")
    @t0 = Time.now
    return
  end
  t1 = Time.now
  if t1-@t0 >= 60
    c1 = MC.player.inventory.count("ENCHANTED_FLINT")*160 + MC.player.inventory.count("FLINT")

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

def farm_gravel
  loop do
    count!
    n = 0
    n += gather_near
    n += gather_far
    n += gather_near
    enchant!
    sleep 0.05
    if n == 0
      puts "[.] idling.."
      #fish!(look_at_water: false) rescue nil
      sleep 5 + rand(5)
    end
    sleep 0.1
  end
end

if $0 == __FILE__
  farm_gravel
end
