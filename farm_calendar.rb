#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'lib/fandom'
require_relative 'lib/common'

@last_enchant = Time.now - 1000
def enchant_agro!
  return if Time.now - @last_enchant < 900
  system "./enchant.rb agro"
  @last_enchant = Time.now
end

def farm_sugar!
#  MC.chat! "#set replantCrops true"
#  sleep 1
  MC.chat! "#goto 10 2 -10"
  wait_for(max_wait: 20) { MC.player.pos.y < 4 }
  4.times do
    MC.chat! "#farm"
    sleep 300
  end
ensure
  MC.chat! "#stop"
#  MC.chat! "#set replantCrops false"
end

#MC.chat! "#set replantCrops false"

#unstash!("PREHISTORIC_EGG")
loop do
#  if MC.player.inventory.count("EGG") > 5
#    stash! "EGG"
#  end

  if MC.current_map != "Garden"
    MC.chat! "/warp garden"
    wait_for { MC.current_map == "Garden" }
  end

  now = Skytime.now
  if (c=Fandom.farming_calendar[now.day_no])
    if c['crops'].include?('Mushroom')
      ai_move_to Pos.new(100, 72, 100) if MC.current_zone != "Plot: 8"
      system "./farm_local.rb --oneshot red_mushroom brown_mushroom"
    elsif c['crops'].include?('Pumpkin')
      system "./farm_pumpkin.rb --oneshot"
    elsif c['crops'].include?('Melon')
      system "./farm_melon.rb --oneshot"
    elsif c['crops'].include?('Cactus')
      system "./farm_cactus.rb --oneshot"
    elsif c['crops'].include?('Wheat')
      system "./farm_wheat.rb --oneshot"
#    elsif c['crops'].include?('Potato')
#      ai_move_to Pos.new(-100, 71, -100) if MC.current_zone != "Plot: 5"
#      system "./farm_local.rb --oneshot"
    elsif c['crops'].include?('Sugar')
      ai_move_to Pos.new(100, 72, 0) if MC.current_zone != "Plot: 3"
      system "./farm_local.rb --oneshot"
    elsif c['crops'].include?('Carrot')
      system "./farm_carrot.rb --oneshot"
    else
      enchant_agro!
      #system "./farm_local.rb --oneshot"
      system "./farm_pumpkin.rb --oneshot"
      system "./farm_melon.rb --oneshot"
      break
    end
    sleep 1
    next
  end

  #system "./farm_local.rb --oneshot"
  system "./farm_pumpkin.rb --oneshot"
  system "./farm_melon.rb --oneshot"
  sleep 1
end
