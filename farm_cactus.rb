#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'enchant'

@oneshot = ARGV.delete('--oneshot')

@boxes = []

13.times do |i|
  @boxes << {
    minX: -44.65+7*i, minY: 71, minZ: 50,
    maxX: -39+7*i,    maxY: 73, maxZ: 141,
  }
end

YAW_D = 5

def farm_cacti!
  if MC.player.pos.z < 95
    @boxes.sort_by{ |box| distance(Pos.new(box[:minX], box[:minY], box[:minZ])) }.each do |box|
      c = MC.blocks!(box: box)['blocks'].count{ |b| b['id'] == 'minecraft:cactus' }
      next if c < 200

      ai_move_to Pos.new(box[:minX], box[:minY], box[:minZ]), timeout_ticks: 4
      MC.set_pitch_yaw! pitch: rand(), yaw: -90+YAW_D+(rand()-0.5)
      MC.travel! :back

      speedup!
      MC.press_key! 'key.mouse.left'
      MC.press_key! 'd'
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      while MC.player.pos.z < box[:maxZ] && (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) < 15
        if MC.player.inventory.full?
          MC.release_key! 'd'
          enchant_inventory!
          MC.press_key! 'd'
        end
        sleep 0.1
        MC.invalidate_cache!
      end
      MC.release_key! 'key.mouse.left'
      MC.release_key! 'd'
      break
    end
  else
    @boxes.sort_by{ |box| distance(Pos.new(box[:minX], box[:minY], box[:maxZ])) }.each do |box|
      c = MC.blocks!(box: box)['blocks'].count{ |b| b['id'] == 'minecraft:cactus' }
      next if c < 200

      ai_move_to Pos.new(box[:minX], box[:minY], box[:maxZ]), timeout_ticks: 4
      MC.set_pitch_yaw! pitch: rand(), yaw: -90-YAW_D+(rand()-0.5)
      MC.travel! :back

      speedup!
      MC.press_key! 'key.mouse.left'
      MC.press_key! 'a'
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      while MC.player.pos.z > box[:minZ] && (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) < 15
        if MC.player.inventory.full?
          MC.release_key! 'a'
          enchant_inventory!
          MC.press_key! 'a'
        end
        sleep 0.1
        MC.invalidate_cache!
      end
      MC.release_key! 'key.mouse.left'
      MC.release_key! 'a'
      break
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
    farm_cacti!
    break if @oneshot
  end
end
