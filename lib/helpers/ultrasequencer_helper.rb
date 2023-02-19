#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'base_helper'

class UltrasequencerHelper < BaseHelper
  SCREEN_TITLE = /Ultrasequencer \(.+\)/

  SLOTS = {
    "Supreme" => 
        %w"10  11  12  13  14  15  16
           19  20  21  22  23  24  25
           28  29  30  31  32  33  34".map(&:to_i),

    "Transcendent" => 
        %w"10  11  12  13  14  15  16
           19  20  21  22  23  24  25
           28  29  30  31  32  33  34
           37  38  39  40  41  42  43".map(&:to_i),

    "Metaphysical" => 
        %w" 9  10  11  12  13  14  15  16  17
           18  19  20  21  22  23  24  25  26
           27  28  29  30  31  32  33  34  35
           36  37  38  39  40  41  42  43  44".map(&:to_i),
  }

  MODE_SLOT_IDX = 49

  def initialize
    @finished_screens = {}
  end

  def handle_screen screen
    sync_id = screen.sync_id
    return false if @finished_screens.key?(sync_id)

    round = 1
    pattern = []
    prev_pattern = []
    prev_msg = ""
    level = nil
    while MC.screen && MC.screen.title =~ SCREEN_TITLE
      wait_for(max_wait: nil) do
        MC.screen && (
          MC.screen.slots[MODE_SLOT_IDX].stack.is_a?(:glowstone) ||
          MC.screen.slots[MODE_SLOT_IDX].stack.is_a?(:clock)
        )
      end
      mode_stack = MC.screen.slots[MODE_SLOT_IDX].stack # glowstone => remember, clock => play

      if MC.screen.title =~ /Ultrasequencer \((.+)\)/
        level = $1
      end

      msg = [mode_stack].map(&:display_name).join(", ")
      puts "[*] #{msg}".white if msg != prev_msg
      prev_msg = msg

      case msg 
      when /Remember the pattern/
        t = SLOTS[level].map { |idx| MC.screen.slots[idx] }.
          find_all { |slot| !slot.empty? }.
          sort_by{ |slot| slot.stack.size }.
          map(&:id)

        if t.size > pattern.size
          pattern = t
          if pattern != prev_pattern
            puts "[.] pattern ##{pattern.size}: #{pattern}"
            prev_pattern = pattern

            if pattern.size == 22
              puts "[*] all done!".green
              @finished_screens[sync_id] = true
              return true
            end
          end
        end
      when /Timer:/
        pattern.each do |slot_id|
          MC.screen.slots[slot_id].click!
          sleep(0.2 + rand()/2)
        end
      end

      sleep 0.1
    end
  end
end

if $0 == __FILE__
  require_relative '../common'
  h = UltrasequencerHelper.new
  h.debug = true
  loop do
    if MC.screen
      h.handle_screen MC.screen
    end
    sleep 0.5
  end
end
