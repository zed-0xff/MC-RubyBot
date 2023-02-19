#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'base_helper'

# level 1 slots:
#
#      04      round
#  12  13  14
#  21  22  23
#  30  31  32
#
#      49      timer

# level 2 slots:
#
#          04
#  11  12  13  14  15
#  20  21  22  23  24
#  29  30  31  32  33
#
#          49

#===== Chronomatron (Supreme)
#                04
#    10  11  12  13  14  15  16
#    19  20  21  22  23  24  25
#    28  29  30  31  32  33  34
#
#                49

#===== Chronomatron (Transcendent)
#                04
#        11  12  13  14
#        20  21  22  23
#            30  31  32  33
#            39  40  41  42
#                49

#===== Chronomatron (Metaphysical) --- 10 colors in 2 rows
#                04
#        11  12  13  14  15
#        20  21  22  23  24
#        29  30  31  32  33
#        38  39  40  41  42
#                49

class ChronomatronHelper < BaseHelper
  SCREEN_TITLE = /Chronomatron \(.+\)/

  ROUND_SLOT_IDX = 4
  MODE_SLOT_IDX = 49
  FIRST_NOTE_SLOT = {
    'High'    => 12,
    'Grand'   => 11,
    'Supreme' => 10,
    'Transcendent' => 11,
    'Metaphysical' => 11,
  }

  TIMEOUT = 5

  def initialize
    @finished_screens = {}
    @debug = true
  end

  def get_sounds round, msg
    twd = Time.now # watchdog
    tick0 = MC.last_tick
    notes = []
    prev_index = 0
    loop do
      r = MC.get_sounds!(prev_index: prev_index)
      r['sounds'].each do |sound|
        next if sound['id'] != 'minecraft:block.note_block.pling'
        next if sound['tick'] < tick0
        prev_index = [sound['index'], prev_index].max

        # 0.5 RED     1
        # 0.6 BLUE    2
        # 0.7 LIME    3
        # 0.8 YELLOW  4
        # 0.9         5 => 4
        # 1.0 AQUA    6 => 5
        # 1.1 PINK    7 => 6
        # 1.2 GREEN   8 => 7
        note = (sound['pitch'].floor(1)*10 - 5).to_i
        note -= 1 if note >= 5

        if @debug
          printf "\n[d] %f => %d", sound['pitch'], note
        else
          printf "%d ", note
        end

        notes << note
        if notes.size == round
          puts
          return notes
        end
        twd = Time.now
      end
      return nil if (Time.now - twd) > TIMEOUT
      sleep 0.01
    end
  end

  def handle_screen screen
    sync_id = screen.sync_id
    return false if @finished_screens.key?(sync_id)

    #puts "[!] equip Guardian pet!".yellow
    last_msg = nil
    round = 1
    @tick = MC.last_tick
    #wait_for("Chronomatron screen", max_wait: nil) { MC.screen && MC.screen.title =~ SCREEN_TITLE }
    while MC.screen && MC.screen.title =~ SCREEN_TITLE
      wait_for(max_wait: nil) { MC.screen && MC.screen.slots[ROUND_SLOT_IDX].stack.is_a?(:bookshelf) }
      bookshelf = MC.screen.slots[ROUND_SLOT_IDX].stack
      mode_stack = MC.screen.slots[MODE_SLOT_IDX].stack # glowstone => remember, clock => play

      msg = [bookshelf, mode_stack].map(&:display_name).join(", ")
      puts "[*] #{msg}".white if msg != last_msg
      last_msg = msg

      if msg =~ /Round:\s+(\d+), Remember the pattern/
        round = $1.to_i
        if round == 16
          puts "[*] all done!".green
          @finished_screens[sync_id] = true
          return true
        end
        printf "[.] Listen: "
        unless (sounds = get_sounds(round, msg))
          puts "FAIL".red
          @finished_screens[sync_id] = false
          break
        end
        wait_for(max_wait: nil) { MC.screen.slots[MODE_SLOT_IDX].stack.is_a?(:clock) }
        sleep(rand()/2)

        level = nil
        base = 
          if MC.screen.title =~ /Chronomatron \((.+)\)/
            level = $1
            FIRST_NOTE_SLOT[level]
          else
            puts "[!] can't get base slot for level #{$1}".red
            12
          end

        screen = MC.screen
        return false unless screen

        printf "[.] Play:  "
        sounds.each do |x|
          printf " %d", x
          case level
          when 'Transcendent'
            case x
            when 0..3
              screen.slots[base+x].click!
            when 4..7
              screen.slots[base+x+15].click!
            when 8
              screen.slots[base+x+14].click!
            end
          when 'Metaphysical'
            case x
            when 0..4
              screen.slots[base+x].click!
            when 5..7
              screen.slots[base+x+13].click!
            when 8
              screen.slots[31].click!
            when 10
              screen.slots[32].click!
            when 14
              screen.slots[33].click!
            end
          else
            screen.slots[base+x].click!
          end
          sleep(0.2 + rand()/4)
        end
        puts
      else
        sleep 0.1
      end
    end
  end
end

if $0 == __FILE__
  require_relative '../common'
  h = ChronomatronHelper.new
  h.debug = true
  loop do
    if MC.screen
      h.handle MC.screen
    end
    sleep 0.5
  end
end
