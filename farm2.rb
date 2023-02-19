#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'autoattack'
require_relative 'enchant'
#require_relative 'fish'

if ARGV.any?
  x = ARGV[0]
  if x["minecraft:"]
    BLOCK_IDS = ARGV
  else
    BLOCK_IDS = %W'minecraft:#{x}_log minecraft:#{x}_wood'
  end
else
  BLOCK_IDS = %w'minecraft:oak_log minecraft:oak_wood'
end

TARGET    = "LOG"
ETARGET   = "ENCHANTED_OAK_LOG"

BREAK_DELAY = 0.6
SCAN_RANGE = 22

def debug
  false
end

def gather_near
  r = MC.blocks!
  blocks = r['blocks']

  blocks = blocks.
    find_all{ |b| BLOCK_IDS.include?(b['id']) }.
    sort_by{ |b| distance(b['pos']) }

  puts "[.] #{blocks.size} near blocks"

  blocks.each do |lp|
    next if lp['pos']['y'] >= MC.player.pos.y+4

    r = MC.look_at_block! lp['pos']
    while BLOCK_IDS.include?(r.dig('player', 'looking_at', 'block', 'id'))
      sleep 0.05
      r = MC.look_at_block! lp['pos']
    end
  end
  blocks.size
end

@last_gotos = []

def gather_far
  r = MC.blocks! radius: SCAN_RANGE, radiusY: 5
  blocks = r['blocks']

  blocks = blocks.
    find_all{ |b| BLOCK_IDS.include?(b['id']) }.
    sort_by{ |b| distance(b['pos']) }

  puts "[.] #{blocks.size} far blocks"

  blocks.each do |lp|
    next if lp['pos']['x'] in -202..-201
    next if lp['pos']['y'] >= MC.player.pos.y+4
    next if distance(lp['pos']) < 4

    if distance(lp['pos']) < BLOCK_REACHABLE_DISTANCE
      MC.look_at_block! lp['pos']
    else
      MC.look_at! lp['pos']
    end

    next if @last_gotos.include?(lp['pos'])
    @last_gotos << lp['pos']
    @last_gotos.pop if @last_gotos.size > 15

    pos0 = MC.player.pos
    MC.chat!("#goto " + lp['pos'].values.map(&:to_s).join(" "), quiet: !debug)
    sleep 1
    wait_for(max_wait: 5, raise: false) do
      r = MC.look_at! lp['pos']
      m = MC.player.dig('nbt', 'Motion')
      ( BLOCK_IDS.include?(r.dig('player', 'looking_at', 'block', 'id')) ) ||
        (m[0] == 0 && m[2] == 0)
    end
    MC.chat!("#stop", quiet: !debug)
    pos1 = MC.player.pos
    break if pos0 != pos1
  end
  blocks.size
end

def count!
  unless @tstart
    @tstart = Time.now
    @c0 = MC.player.inventory.count(ETARGET)*160 +
      MC.player.inventory.count(TARGET) +
      MC.player.current_tool.dig('tag', 'ExtraAttributes', 'compact_blocks').to_i
    @t0 = Time.now
    return
  end
  t1 = Time.now
  if t1-@t0 >= 60
    c1 = MC.player.inventory.count(ETARGET)*160 +
      MC.player.inventory.count(TARGET) +
      MC.player.current_tool.dig('tag', 'ExtraAttributes', 'compact_blocks').to_i

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

def farm
  loop do
    count!
    n = 0
    n += gather_near
    n += gather_far
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
  farm
end
