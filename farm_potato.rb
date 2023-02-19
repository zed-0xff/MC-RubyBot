#!/usr/bin/env ruby
require_relative 'enchant'

@tstart = Time.now

CROPS = {
  "minecraft:carrots"  => false,
  "minecraft:potatoes" => true,
}

def count_around radius
  scan(radius: radius, radiusY: 4)['blocks'].count { |b| CROPS[b['id']] }
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

  ai_move_to(start_positions.random) { count_around(3) > 20 }

  loop do
    n = count_around(10)
    printf "[.] %d crops around\n", n
    break if n < 20

    select_tool /_HOE/
    chat "#farm 20"
    sleep 0.5
    #press_key 'key.mouse.left', 0

    a = []
    200.times do
      respect_player
      if MC.player.inventory.full?
        chat "#stop"
        enchant_inventory! 
        stash!(/^ENCHANTED_/)
        chat "#farm 20"
      end
      n = count_around(10)
      a << n
      printf "[.] %d crops around\n", n
      break if a.size >= 3 && a[-3..-1].all?{ |x| x < 10 }
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
  printf "[.] %s %2ds, %3d potatoes per run, %2d potatoes/s\n", formatted_dt, (t1-t0), (c1-c0), (c1-c0)/(t1-t0)

#  chat "/warp home"
#  sleep(1+rand()*2)
rescue Interrupt
  chat "#stop"
  exit
ensure
  chat "#stop"
end

if CROPS["minecraft:carrots"]
  START_POSITIONS = {
    barn: [ Pos[127, 76, -263] ],
    hub: [ Pos[0, 69, 5] ],
  }
elsif CROPS["minecraft:potatoes"]
  START_POSITIONS = {
    barn: [ Pos[162, 77, -260], Pos[180, 84, -270] ],
  }
end

if $0 == __FILE__
  chat "#stop"
  loop do
    chat "/warp hub"
    wait_for { MC.current_map == 'Hub' }
    sleep 1
    if START_POSITIONS[:hub]
      chat "/warp hub"
      sleep 0.5
      speedup!
      farm_carrot! START_POSITIONS[:hub]
    end

    chat "/warp barn"
    sleep 1
    speedup!
    farm_carrot! START_POSITIONS[:barn]
    break if ARGV[0] == '1'
  end
end
