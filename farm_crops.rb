#!/usr/bin/env ruby
require_relative 'enchant'

if ARGV.size != 1
  puts "gimme veg name"
  exit 1
end

@tstart = Time.now

def is_crop?(id)
  ARGV.any? { |x| id == "minecraft:#{x}" }
end

def count_around radius
  scan(radius: radius, radiusY: 4)['blocks'].count { |b| is_crop?(b['id']) }
end

def farm_crops! start_positions, range=nil
  c0 = MC.player.inventory.count("ENCHANTED_WHEAT")*160 +
    MC.player.inventory.count("WHEAT")
  t0 = Time.now

#  if current_zone != "The Farming Islands"
#    chat "/warp home" unless current_zone == 'Private Island'
#    wait_for(max_wait: 10) { current_zone == 'Private Island' }
#    chat "/warp barn"
#    wait_for(max_wait: 10) { current_zone == "The Farming Islands" }
#  end

  if start_positions
    ai_move_to(start_positions.random) { count_around(3) > 17 }
  end

  loop do
    n = count_around(10)
    printf "[.] %d crops around\n", n
    break if n < 30

    select_tool /_HOE_WHEAT_/
    chat "#farm #{range}"
    sleep 0.5
    #press_key 'key.mouse.left', 0

    a = []
    poss = []
    200.times do
      #respect_player
      if MC.player.inventory.full?
        chat "#stop"
        enchant_inventory! 
#        if MC.player.inventory.count(/^ENCHANTED_/) >= 64
#          tc0 = MC.player.inventory.count("ENCHANTED_WHEAT")*160 + MC.player.inventory.count("WHEAT")
#          stash!(/^ENCHANTED_/)
#          tc1 = MC.player.inventory.count("ENCHANTED_WHEAT")*160 + MC.player.inventory.count("WHEAT")
#          c0 -= (tc1-tc0)
#        end
        chat "#farm #{range}"
      end
      n = count_around(10)
      a << n
      poss << MC.player.pos
      printf "[.] %d crops around\n", n
      break if a.size >= 3 && a[-3..-1].all?{ |x| x < 20 }
      break if poss.size >= 5 && poss[-5..-1].uniq.size == 1
      sleep 1
    end
    #release_key 'key.mouse.left'
  end
  chat "#stop"

  c1 = MC.player.inventory.count("ENCHANTED_WHEAT")*160 +
    MC.player.inventory.count("WHEAT")
  t1 = Time.now

  dt = Time.now - @tstart
  formatted_dt = "%02d:%02d" % [dt/3600, (dt/60)%60]
  printf "[.] %s %2ds, %3d crops per run, %2d crops/s\n", formatted_dt, (t1-t0), (c1-c0), (c1-c0)/(t1-t0)

#  chat "/warp home"
#  sleep(1+rand()*2)
rescue Interrupt
  chat "#stop"
  exit
ensure
  chat "#stop"
end

START_POSITIONS = {
  carrots: {
    barn: [
      Pos[127, 76, -263],
      Pos[122, 80, -280],
      Pos[140, 90, -301],
      Pos[140, 86, -293],
    ],
    hub: [
      Pos[-3, 69, 8],
    ]
  },
  wheat: {
    hub: [
      Pos[27, 70, -144],
      Pos[24, 71, -180],
      Pos[59, 72, -183],
      Pos[74, 72, -159],
      Pos[64, 71, -133],
    ],
    barn: [
      Pos[130, 72, -224],
    ]
  },
}

MIN_COUNTS = {
  carrots: 20,
  wheat:   30,
}

def farm_zone zone
  slept = false
  2.times do
    START_POSITIONS[ARGV[0].to_sym][zone].each_with_index do |pos, idx|
#      if distance(pos) > 60
#        ai_move_to(pos) { count_around(3) > 17 }
#      end
      nc = MC.blocks!(target: pos, expand: {x: 3, y: 1, z: 3}, filter: "minecraft:#{ARGV[0]}")['blocks'].size
      if nc == 0 && !slept
        sleep 1
        nc = MC.blocks!(target: pos, expand: {x: 3, y: 1, z: 3}, filter: "minecraft:#{ARGV[0]}")['blocks'].size
        slept = true
      end
      printf "[*] pos #%d: %d crops\n", idx, nc
      next if nc < MIN_COUNTS[ARGV[0].to_sym]
      farm_crops!([pos])
    end
  end
end

if $0 == __FILE__
  chat "#stop"
  chat "#set allowBreak false"
  loop do
    MC.chat! "/warp hub"
    wait_for { MC.current_map == 'Hub' }
    farm_zone :hub

    MC.chat! "/warp barn"
    wait_for { MC.current_map == 'The Farming Islands' }
    farm_zone :barn
    break if ARGV[0] == '1'
  end
end
