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

  targets = blocks.
    find_all{ |b| b['id'] == 'minecraft:nether_wart' }.
    sort_by{ |b| distance(b['pos']) }

  #puts "[.] #{targets.size} near targets"

  targets.each do |lp|
    r = MC.look_at_block! lp['pos']
    #p r.dig('player', 'looking_at')
    sleep 0.1
  end
  targets.size
end

def count!
  unless @tstart
    @tstart = Time.now
    @c0 = MC.player.inventory.count("ENCHANTED_NETHER_STALK")*160 + MC.player.inventory.count("NETHER_STALK")
    @t0 = Time.now
    return
  end
  t1 = Time.now
  if t1-@t0 >= 60
    c1 = MC.player.inventory.count("ENCHANTED_NETHER_STALK")*160 + MC.player.inventory.count("NETHER_STALK")

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

def gather1
  #MC.chat! "/warp hub"
  #sleep 1
  MC.chat! "#goto 34 68 -73"
  wait_for(max_wait: 10) { (MC.player.pos.x.round in 34..35) && (MC.player.pos.z.round in -73..-72) }
  MC.script do
    chat! "#stop"
    set_pitch_yaw! yaw: 0
    press_key! 'key.mouse.left'
  end
  18.times { MC.travel! :forward }

  gather_near

  MC.set_pitch_yaw! yaw: 0
  20.times { MC.travel! :back }
  MC.release_key! 'key.mouse.left'
end

def gather2
  #MC.chat! "/warp hub"
  #sleep 1
  MC.chat! "#goto 52 68 -67"
  wait_for(max_wait: 10) { (MC.player.pos.x.round in 52..53) && (MC.player.pos.z.round in -67..-66) }

  MC.script do
    chat! "#stop"
    set_pitch_yaw! yaw: 0
    press_key! 'key.mouse.left'
  end
  18.times { MC.travel! :forward }

  gather_near
  MC.release_key! 'key.mouse.left'
end

def sell
  MC.chat! "#goto 13 70 -72"
  sleep 3
  MC.chat! "#stop"
  MC.interact_entity! network_id: 447
  wait_for { MC.screen }
  MC.screen.player_slots.each do |slot|
    slot.click! if slot.stack.is_a?("ENCHANTED_NETHER_STALK")
  end
  MC.close_screen!
end

def warp_home
  MC.chat! "/warp home"
  wait_for { MC.current_map == "Private Island" }
  sleep 1
end

def farm_wart
  loop do
    #warp_home
    warp_random_hub
    if MC.player.inventory.full?
      enchant_inventory!
      #sell
    end
    gather1
    gather2
  end
end

if $0 == __FILE__
  farm_wart
end
