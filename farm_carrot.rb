#!/usr/bin/env ruby
require_relative 'enchant'

@tstart = Time.now

VEGS = {
  "minecraft:carrots"  => true,
  "minecraft:potatoes" => false,
}

def count_around radius
  scan(radius: radius, radiusY: 4)['blocks'].count { |b| VEGS[b['id']] }
end

def farm_carrot! start_positions
  c0 = MC.player.inventory.count("ENCHANTED_CARROT")*160 +
    MC.player.inventory.count("CARROT")
  t0 = Time.now

#  if current_zone != "The Farming Islands"
#    chat "/warp home" unless current_zone == 'Private Island'
#    wait_for(max_wait: 10) { current_zone == 'Private Island' }
#    chat "/warp barn"
#    wait_for(max_wait: 10) { current_zone == "The Farming Islands" }
#  end

  ai_move_to(start_positions.random) { count_around(3) > 17 }

  loop do
    n = count_around(10)
    printf "[.] %d carrots around\n", n
    break if n < 20

    select_tool /_HOE/
    chat "#farm"
    sleep 0.5
    #press_key 'key.mouse.left', 0

    a = []
    poss = []
    200.times do
      #respect_player
      if MC.player.inventory.full?
        chat "#stop"
        enchant_inventory! 
        if MC.player.inventory.count(/^ENCHANTED_/) >= 64
          tc0 = MC.player.inventory.count("ENCHANTED_CARROT")*160 + MC.player.inventory.count("CARROT")
          stash!(/^ENCHANTED_/)
          tc1 = MC.player.inventory.count("ENCHANTED_CARROT")*160 + MC.player.inventory.count("CARROT")
          c0 -= (tc1-tc0)
        end
        chat "#farm"
      end
      n = count_around(10)
      a << n
      poss << MC.player.pos
      printf "[.] %d carrots around\n", n
      break if a.size >= 3 && a[-3..-1].all?{ |x| x < 5 }
      break if poss.size >= 5 && poss[-5..-1].uniq.size == 1
      sleep 1
    end
    #release_key 'key.mouse.left'
  end
  chat "#stop"

  c1 = MC.player.inventory.count("ENCHANTED_CARROT")*160 +
    MC.player.inventory.count("CARROT")
  t1 = Time.now

  dt = Time.now - @tstart
  formatted_dt = "%02d:%02d" % [dt/3600, (dt/60)%60]
  printf "[.] %s %2ds, %3d carrot per run, %2d carrot/s\n", formatted_dt, (t1-t0), (c1-c0), (c1-c0)/(t1-t0)

#  chat "/warp home"
#  sleep(1+rand()*2)
rescue Interrupt
  chat "#stop"
  exit
ensure
  chat "#stop"
end

START_POSITIONS = {
  barn: [
    Pos[127, 76, -263],
    Pos[122, 80, -280],
    Pos[140, 90, -301],
    Pos[140, 86, -293],
  ],
  hub: [
    Pos[-3, 69, 8],
  ]
}

if $0 == __FILE__
  chat "#stop"
  chat "#set allowBreak false"
  #unstash!("PREHISTORIC_EGG")
  loop do
    loop do
      chat "/warp hub"
      sleep 1
      MC.invalidate_cache!
      break if MC.current_map == 'Hub'
    end
    chat "/warp hub"
    sleep 0.5
    speedup!
    farm_carrot! START_POSITIONS[:hub]

    chat "/warp barn"
    sleep 1
    speedup!
    farm_carrot! START_POSITIONS[:barn]
    break if ARGV[0] == '1'
  end
end
