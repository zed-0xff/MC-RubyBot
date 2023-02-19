#!/usr/bin/env ruby
require_relative 'lib/common'

def stop!
  MC.chat! "#stop" unless @stopped
  @stopped = true
end

def tunnel!
  return unless @stopped
  MC.set_pitch_yaw! yaw: @yaw0
  MC.chat! "#tunnel 3 5 100"
  @stopped = false
end

@negatives = Set.new
@prev_time = Time.now - 10

def gather_near
  return false if @negatives.include?(MC.player.pos)
  return false if Time.now - @prev_time < 5

  r = MC.blocks!
  blocks = r['blocks']

  ores = blocks.
    find_all{ |b| b['id'] =~ /ore$/ }.
    find_all{ |b| distance(b['pos']) < 4.2 }.
    sort_by{ |b| distance(b['pos']) }

  was = false
  ores.each do |b|
    printf "[.] %3.1f  %s\n", distance(b['pos']), b['id'].sub('minecraft:','')
    stop!
    20.times do
      r = MC.look_at!(b['pos']).dig('player', 'looking_at', 'block')
      break unless r
      was = true
      sleep 0.2
    end
  end
  unless was
    @prev_time = Time.now
    @negatives << MC.player.pos
  end
  was
end

stop!
MC.chat! "#set allowBreak true"
@yaw0 = MC.player.yaw

begin
  loop do
    while gather_near
      # gather near
    end
    tunnel!
    sleep 2
  end
rescue Interrupt
  MC.chat! "#stop"
end
