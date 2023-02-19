#!/usr/bin/env ruby
require_relative 'enchant'

@tstart = Time.now

VEGS = {
  "minecraft:wheat"  => true,
}

def count_around radius
  scan(radius: radius, radiusY: 4)['blocks'].count { |b| VEGS[b['id']] }
end

def farm_wheat! start_positions, range=nil
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
    autorun force: true
    ai_move_to(start_positions.random) { count_around(3) > 17 }
  end

  loop do
    n = count_around(10)
    printf "[.] %d wheat around\n", n
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
        if MC.player.inventory.count(/^ENCHANTED_/) >= 64
          tc0 = MC.player.inventory.count("ENCHANTED_WHEAT")*160 + MC.player.inventory.count("WHEAT")
          stash!(/^ENCHANTED_/)
          tc1 = MC.player.inventory.count("ENCHANTED_WHEAT")*160 + MC.player.inventory.count("WHEAT")
          c0 -= (tc1-tc0)
        end
        chat "#farm #{range}"
      end
      n = count_around(10)
      a << n
      poss << MC.player.pos
      printf "[.] %d wheat around\n", n
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
  printf "[.] %s %2ds, %3d wheat per run, %2d wheat/s\n", formatted_dt, (t1-t0), (c1-c0), (c1-c0)/(t1-t0)

#  chat "/warp home"
#  sleep(1+rand()*2)
rescue Interrupt
  chat "#stop"
  exit
ensure
  chat "#stop"
end

START_POSITIONS = {
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
}

if $0 == __FILE__
  chat "#stop"
  chat "#set allowBreak false"
  loop do
    #warp_random_hub
    while MC.current_map != 'Hub'
      chat "/warp hub"
      wait_for(raise: false) { MC.current_map == 'Hub' }
    end
    #speedup!
    slept = false
    2.times do
      START_POSITIONS[:hub].each_with_index do |pos, idx|
        nc = MC.blocks!(target: pos, expand: {x: 3, y: 1, z: 3}, filter: "minecraft:wheat")['blocks'].size
        if nc == 0 && !slept
          sleep 1
          nc = MC.blocks!(target: pos, expand: {x: 3, y: 1, z: 3}, filter: "minecraft:wheat")['blocks'].size
          slept = true
        end
        printf "[*] pos #%d: %d crops\n", idx, nc
        next if nc < 30
        farm_wheat!([pos])
      end
    end

    chat "/warp barn"
    wait_for(raise: false){ MC.current_map == 'The Farming Islands' }
    if MC.current_map == 'The Farming Islands'
      farm_wheat!(START_POSITIONS[:barn], 14)
    end
    break if ARGV[0] == '1'
  end
end
