#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'base_helper'

class SuperpairsHelper < BaseHelper

  SCREEN_TITLE = /^Superpairs \(/
  SKIP_SLOTS = [4, 49] # timer, clicks count

  def initialize
    @finished_screens = {}
  end

  def handle_screen screen
    index = 'A'
    cache = {}
    labels = {}
    while MC.screen && MC.screen.title =~ SCREEN_TITLE
#      locks = []
      MC.screen.slots.each do |slot|
        next if slot['inventoryId'] == 'player'
        next if SKIP_SLOTS.include?(slot['id'])
        next if slot.empty? || 
          slot.stack.display_name == "?" || 
          slot.stack.display_name =~ /Click any button/ ||
          slot.stack.display_name =~ /Click a second button!/ ||
          slot.stack.display_name =~ /Next button is instantly/ ||
          slot.stack.display_name =~ /Instant Find/

        x = screen.x + slot.x + 1
        y = screen.y + slot.y + 1

        thash = slot.stack.tag.hash
        unless cache[thash]
          title = slot.stack.display_name
          if title == "Enchanted Book"
            title = slot.stack.lore.sub(/^Item Reward/,'').strip.split("\n").first
            puts "[*] #{index}: #{title}".green
          else
            puts "[*] #{index}: #{title}"
          end
          p slot.stack.tag
          p slot.stack.lore
          #puts
          cache[thash] = index
          index = index.succ
#          locks << slot.id
        end
        labels[[x,y]] = cache[thash]
      end

      if labels.any? # || locks.any?
        MC.script do
          labels.each do |coords,text|
            x,y = coords
            add_hud_text! text, x: x, y: y, ttl: 200, color: 0x00ff00
          end
#          locks.each do |slot_id|
#            lock_slot! slot_id
#          end
        end
      end
      sleep 0.05
      MC.invalidate_cache!
    end
  end
end

if $0 == __FILE__
  ChronomatronHelper.new.solve
end
