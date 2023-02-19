#!/usr/bin/env ruby
require_relative 'lib/common'
require_relative 'lib/map'
require_relative 'enchant'

MC.stubborn = false

@ori = -1

def maps
  r = scan(
    offset: { x: -2*@ori, y: 2, z: 0 },
    expand: { x: 1, y: 1, z: 3 },
  )

  maps = Hash.new{ |k,v| k[v] = Map.new }
  blocks = r['blocks']
  blocks.each do |block|
    y = block['pos']['y']
    maps[y].put(block, (block['id'] == 'minecraft:cocoa') && block['age'])
  end
  maps
end

def cut!
  n = 0
  maps.each do |y, map|
    map.rz.each do |z|
      map.rx.each do |x|
        if map[z][x] == 'J' && map[z][x+@ori] == 2
          select_tool "COCO_CHOPPER", delay_next: -1
          pos = { x: x+@ori, y: y, z: z }
          if MC.look_at_block!(pos, delay_next: -1)['lookAtBlock']
            sleep 0.05
            MC.break_block! delay_next: -1, oneshot: true
            n += 1
            sleep 0.1
          else
            puts "[?] look failed"
          end
        end
      end
    end
  end
  n
end

def plant!
  return false unless MC.player.has?("INK_SACK:3")
  maps.each do |y, map|
    map.rz.each do |z|
      map.rx.each do |x|
        if map[z][x] == 'J' && map[z][x+@ori].nil?
          pos = { x: x, y: y, z: z }
          side = (@ori == -1) ? :east : :west
          if MC.look_at_block!(pos, delay_next: -1, side: side)['lookAtBlock']
            select_tool "INK_SACK:3", delay_next: -1
            sleep 0.05
            MC.interact_block! delay_next: -1
            sleep 0.05
#            $stdout << 'p'
          end
        end
      end
    end
  end
end

NEXT_TRAVEL_DIR = {
  left: :right,
  right: :left,
}

def move!
  @travel_dir ||= :right

  z0 = MC.player.pos.z
  MC.set_pitch_yaw! yaw: 90*@ori, delay_next: -1
  15.times do
    MC.travel! @travel_dir
    sleep 0.05

    MC.invalidate_cache!
    if MC.player.pos.z == z0
      center!
      if @ori == 1
        x0 = MC.player.pos.x
        8.times do
          MC.travel!(:fwd)
          sleep 0.05
        end

        MC.invalidate_cache!
        if (MC.player.pos.x - x0).abs < 1.5
          100.times do
            MC.travel!(:back)
            sleep 0.05
          end
          center!
          return
        end

        center!
      end
      @ori = -@ori
      return
    end
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

def center!
  MC.set_pitch_yaw! yaw: 90*@ori, delay_next: -1
  dx0 = dx = MC.player.pos.x - MC.player.pos.x.to_i
  amount = 0.4
  while dx.round(1).abs != 0.5
    if dx > 0
      if dx > 0.5
        MC.travel!(:back, amount: amount)
      else
        MC.travel!(:fwd, amount: amount)
      end
    else
      if dx > -0.5
        MC.travel!(:back, amount: amount)
      else
        MC.travel!(:fwd, amount: amount)
      end
    end
    sleep 0.2
    MC.invalidate_cache!
    dx = MC.player.pos.x - MC.player.pos.x.to_i
    amount = amount/2
    if amount < 0.01
      puts "[?] failed to center, dx0=#{dx0}, dx=#{dx}"
      break
    end
  end
end

def count!
  unless @tstart
    @tstart = Time.now
    @c0 = MC.player.inventory.count("ENCHANTED_COCOA")*160 + MC.player.inventory.count("INK_SACK:3")
    @t0 = Time.now
    return
  end
  t1 = Time.now
  if t1-@t0 >= 60
    c1 = MC.player.inventory.count("ENCHANTED_COCOA")*160 + MC.player.inventory.count("INK_SACK:3")

    dt = t1 - @tstart
    formatted_dt = "%02d:%02d" % [dt/3600, (dt/60)%60]
    printf "[.] %s %2ds, %3d cocoa/min\n", formatted_dt, (t1-@t0), (c1-@c0)/(t1-@t0)*60

    @c0 = c1
    @t0 = t1
  end
end

center!

loop do
  count!
  cut!
  plant!
  move!
  enchant! && stash!("ENCHANTED_COCOA")
end
