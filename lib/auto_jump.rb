#!/usr/bin/env ruby
# frozen_string_literal: true
require 'singleton'

class AutoJump
  include Singleton

  HOLD_INTERVAL = 0.2
  INTERVAL = 0.2
  MULT = 1.2

  attr_accessor :debug

  def initialize
    @prev_pos = nil
    @jumping = false
    @blocks = {}
    @last_jump = nil
    @debug = false
  end

  def jump! player
    pos = player.pos.dup
    unless @prev_pos
      @prev_pos = pos
      return
    end

    printf "[d] %6d %s\n", MC.last_tick, player.dig('nbt', 'OnGround') if debug

    if @jumping
      dt = Time.now - @last_jump
      return (dt > HOLD_INTERVAL) ? unjump! : nil
    end

    @prev_pos.y = pos.y
    return unjump! if pos == @prev_pos
    delta = pos - @prev_pos
    @prev_pos = pos

    if player.dig('nbt', 'OnGround') == 0
      return unjump!
    end

#    if @last_jump && (dt=(Time.now - @last_jump)) < INTERVAL
#      return dt > HOLD_INTERVAL ? unjump! : nil
#    end

    delta.x *= MULT
    delta.z *= MULT
    next_pos = pos + delta
    next_pos.to_i!

    napos = next_pos.values
    napos[1] -= 1

    #p [napos, is_air?(napos)]

    if (next_pos.x != pos.x.to_i || next_pos.z != pos.z.to_i) && is_air?(napos)
      _jump!
    else
      unjump!
    end
  end

  def _jump!
    printf "%d JUMP!\n".green, MC.last_tick
    @jumping = true
    @last_jump = Time.now
    MC.press_key! "space"
  end

  def is_air? napos
    _fetch_blocks unless @blocks.key?(napos)
    @blocks[napos]
  end

  def _fetch_blocks
    blocks = MC.blocks!(radius: 1, radiusY: 2, skip_air: false)['blocks']

    blocks.each do |block|
      apos = block['pos'].values
      @blocks[apos] = block['canPathfindThrough']
    end
  end

  def unjump!
    return unless @jumping
    printf "%d unjump\n", MC.last_tick
    MC.release_key! "space"
    @jumping = false
  end

  def self.jump! player = MC.player
    instance.jump! player
  end
end

if $0 == __FILE__
  require_relative 'common'
  loop do
    MC.status!
    AutoJump.jump!
    sleep 0.001
  end
end
