#!/usr/bin/env ruby
require_relative 'autoattack'
require_relative 'enchant'

MC.cache_ttl = 0.1

POINTS = [
  Pos[129.5, 186, 96],
  Pos[129.5, 186, 18],
]

STRIPES = [124, 129, 134]

@tstart = Time.now

def mine!
  c0 = MC.player.inventory.count("ENCHANTED_COBBLESTONE")*160 +
    MC.player.inventory.count("COBBLESTONE")
  t0 = Time.now

  select_tool /PICKAXE/

  release_key 'key.mouse.left'
  sleep 0.01
  speedup!
  MC.lock_cursor!
  MC.press_key! 'key.mouse.left'

  POINTS.each do |dst|
    #puts "[.] going to #{dst}"
    if MC.player.inventory.full?
      MC.release_key! 'key.mouse.left'
      while MC.player.inventory.full?
        begin
          enchant_inventory!
        rescue
          sleep 1
          retry
        end
        sleep 1
      end
      MC.press_key! 'key.mouse.left'
    end

    loop do
      t = Pos[rand()*12-6, 0, rand*4 - 2]
      next if STRIPES.include?((dst+t).x.to_i)
      dst += t
      break
    end
    MC.look_at! dst
    sleep 0.1

    MC.script do
      set_pitch_yaw! pitch: 32+rand(10)
      press_key! 'w'
    end

    prevdist = 99999
    nbr = 0
    loop do
      sleep 0.1
      MC.invalidate_cache!
      break if MC.current_zone != "Palace Bridge"
      dist = distance(dst)
      break unless dist in 4..90

      break if MC.player['horizontalFacing'] == "south" && MC.player.dig('pos', 'z') > 100


      if dist > prevdist
        puts "[!] #{dist} > #{prevdist}, [#{nbr}]"
        nbr += 1
        break if nbr > 1
     end

      prevdist = dist
      break if respect_player
      if ["minecraft:bedrock", "minecraft:polished_andesite"].include?( MC.player.dig('looking_at', 'block', 'id') )
        if rand(2) == 1
          MC.press_key! 'a'
          sleep((80+rand(60))/1000.0)
          MC.release_key! 'a'
        else
          MC.press_key! 'd'
          sleep((80+rand(60))/1000.0)
          MC.release_key! 'd'
        end
      end
    end
    MC.release_key! 'w'
  end # POINTS.each

  c1 = MC.player.inventory.count("ENCHANTED_COBBLESTONE")*160 +
    MC.player.inventory.count("COBBLESTONE")
  t1 = Time.now

  dt = Time.now - @tstart
  formatted_dt = "%02d:%02d" % [dt/3600, (dt/60)%60]
  printf "[.] %s %2ds, %3d stone per run, %2d stone/s\n", formatted_dt, (t1-t0), (c1-c0), (c1-c0)/(t1-t0)
rescue Interrupt
  MC.release_key! 'key.mouse.left'
  MC.release_key! 'w'
  exit
end

if $0 == __FILE__
  while MC.current_zone == "Palace Bridge" && MC.player.inventory.count("ENCHANTED_COBBLESTONE") < 64*9*2.5
    mine!
  end
  MC.release_key! 'key.mouse.left'
  MC.release_key! 'w'
  set_pitch_yaw pitch: 0
end

