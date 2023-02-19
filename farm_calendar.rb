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
  MC.chat! "#set replantCrops true"
  MC.chat! "/warp home"
  wait_for { MC.current_map == "Private Island" }
  sleep 1
  MC.chat! "#goto 10 2 -10"
  wait_for(max_wait: 20) { MC.player.pos.y < 4 }
  4.times do
    MC.chat! "#farm"
    sleep 300
  end
ensure
  MC.chat! "#stop"
  MC.chat! "#set replantCrops false"
end

MC.chat! "#set replantCrops false"

unstash!("PREHISTORIC_EGG")
loop do
  if MC.player.inventory.count("EGG") > 5
    stash! "EGG"
  end

  now = Skytime.now
  if (c=Fandom.farming_calendar[now.day_no])
    if c['crops'].include?('Sugar')
      farm_sugar!
    elsif c['crops'].include?('Carrot')
      system "./farm_carrot.rb 1"
    elsif c['crops'].include?('Wheat')
      system "./farm_wheat.rb 1"
    elsif c['crops'].include?('Potato')
      system "./farm_potato.rb 1"
    else
      enchant_agro!
      system "./farm_carrot.rb 1"
    end
    sleep 1
    next
  end

  system "./farm_carrot.rb 1"
  sleep 1
end
