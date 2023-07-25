#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'enchant'

@oneshot = ARGV.delete('--oneshot')

@boxes = []

32.times do |i|
  @boxes << {
    minX: -142+2*i-0.1, minY: 72, minZ: 51,
    maxX: -142+2*i+0.1, maxY: 75, maxZ: 140,
  }
end

YAW_D = 5
MIN_C = 200
Y     = 71

def farm_cocoa!
  @boxes.each do |box|
    c = MC.blocks!(box: box, filter: "minecraft:cocoa")['blocks'].count{ |b| b['id'] == 'minecraft:cocoa' && b['age'] == 2 }
    next if c < MIN_C

    if MC.player.pos.z < 95
      ai_move_to Pos.new(box[:minX], Y, box[:minZ]), timeout_ticks: 4, precision: 0.1
      MC.set_pitch_yaw! pitch: -44+rand(), yaw: 180
      MC.travel! :right
      MC.travel! :back, amount: 2
      MC.travel! :left
      MC.travel! :left
      MC.travel! :left

      MC.press_key! 'key.mouse.left'
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      while MC.player.pos.z < box[:maxZ] && (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) < 15
        if MC.player.inventory.full?
          enchant_inventory!
        end
        MC.travel! :back
      end
      MC.release_key! 'key.mouse.left'
    else
      ai_move_to Pos.new(box[:minX], Y, box[:maxZ]), timeout_ticks: 4, precision: 0.1
      MC.set_pitch_yaw! pitch: -44+rand(), yaw: 0
      MC.travel! :right
      MC.travel! :back, amount: 2
      MC.travel! :left
      MC.travel! :left
      MC.travel! :left

      MC.press_key! 'key.mouse.left'
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      while MC.player.pos.z > box[:minZ] && (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) < 15
        if MC.player.inventory.full?
          enchant_inventory!
        end
        MC.travel! :back
      end
      MC.release_key! 'key.mouse.left'
    end
  end
rescue Interrupt
  chat "#stop"
  MC.release_key! 'key.mouse.left'
  MC.release_key! 'a'
  MC.release_key! 'd'
  exit
ensure
  MC.release_key! 'key.mouse.left'
  MC.release_key! 'a'
  MC.release_key! 'd'
end

if __FILE__ == $0
  loop do
    farm_cocoa!
    break if @oneshot
  end
end
