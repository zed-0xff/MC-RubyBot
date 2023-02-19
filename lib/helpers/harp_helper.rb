#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'base_helper'

class HarpHelper < BaseHelper

  SCREEN_TITLE = /^Harp/

  ACCURACY = (ARGV.first || "0.9999").to_f

  def play_note slot_id
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    dt = now - @tprev
    @tprev = now
    if rand() < ACCURACY
      @slots[slot_id].click!
    else
      slot_id += (rand(2) == 1) ? 1 : -1
      @slots[slot_id].click!
    end
    printf "[.] step %2d: dt=%5.3f note %d\n", @step, dt, slot_id
    @step += 1
  end

  def handle_screen screen
    melody = screen.title.split("-", 2).last.strip
    MC.say! "[*] melody: #{melody}".green

    @tprev = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @step = 1
    slot_id = nil
    cache = {}
    sync_id = screen.sync_id

    # XXX TODO rewrite w/o using log
    File.open(File.expand_path(LOG_FNAME), "r") do |f|
      f.seek 0, :END
      @slots = slots = MC.screen.slots # we don't need to update them from mod
      while MC.screen && MC.screen&.sync_id == sync_id
        line = f.gets
        if line
          if line.strip =~ /setStackInSlot\((\d+), \d+, (.+)\) syncId=#{sync_id}$/
            slot_id = $1.to_i
            stack = $2
            cache[slot_id] = stack
            next unless (slot_id in 37..43) && stack['quartz_block']

            nrepeat = 1
            while cache[slot_id-nrepeat*9]['_wool']
              nrepeat += 1
            end

            nrepeat.times do
              play_note slot_id
              sleep(0.2+rand()/5) if nrepeat > 1
            end
          elsif line["note_block.bass"]
            puts "[!] MISS".red
            return false
          end
        end
      end
    end
    true
  end
end
