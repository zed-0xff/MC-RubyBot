#!/usr/bin/env ruby
require_relative 'enchant'

@tstart = Time.now

@noenchant = ARGV.delete('--no-enchant')

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

  loop do
    chat "#farm #{range}"
    sleep 0.5
    #press_key 'key.mouse.left', 0

    a = []
    poss = []
    200.times do
      if MC.player.inventory.full?
        chat "#stop"
        exit if @noenchant
        enchant_inventory! 
        chat "#farm #{range}"
      end
      sleep 1
    end
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

if $0 == __FILE__
  chat "#stop"
  chat "#set allowBreak false"
  loop do
    farm_crops! nil
  end
end
