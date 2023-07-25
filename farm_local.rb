#!/usr/bin/env ruby
require_relative 'enchant'

@tstart = Time.now
@noenchant = ARGV.delete('--no-enchant')
@oneshot = ARGV.delete('--oneshot')
@pos0 = MC.player.pos
@zone0 = MC.current_zone

def farm_crops! range=nil
#  if current_zone != "The Farming Islands"
#    chat "/warp home" unless current_zone == 'Private Island'
#    wait_for(max_wait: 10) { current_zone == 'Private Island' }
#    chat "/warp barn"
#    wait_for(max_wait: 10) { current_zone == "The Farming Islands" }
#  end

  loop do
    chat @cmd
    sleep 0.5
    #press_key 'key.mouse.left', 0

    a = []
    poss = []
    60.times do
      if MC.player.inventory.full?
        chat "#stop"
        exit if @noenchant
        enchant_inventory! 
        chat @cmd
      end
      if MC.current_map != "Garden"
        chat "/warp garden"
        sleep 5
      end
      if MC.current_zone != @zone0
        chat "#stop"
        ai_move_to @pos0
        chat @cmd
      end
      sleep 1
    end
    break if @oneshot
  end
  chat "#stop"

#  chat "/warp home"
#  sleep(1+rand()*2)
rescue Interrupt
  chat "#stop"
  exit
ensure
  chat "#stop"
end

range = ARGV.first
@cmd =
  if range.nil? || range =~ /^\d+$/
    "#farm #{range}"
  else
    "#mine #{ARGV.join(' ')}"
  end

if $0 == __FILE__
  chat "#stop"
  chat "#set allowBreak false"
  select_tool /_HOE/
  loop do
    farm_crops! range
    break if @oneshot
  end
end
