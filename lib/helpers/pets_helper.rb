#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'base_helper'

# slots:
#
# 00 01          04             08
#    10  11  12  13  14  15  16
#    19  20  21  22  23  24  25
#    28  29  30  31  32  33  34
#    37  38  39  40  41  42  43

class PetsHelper < BaseHelper

  SCREEN_TITLE = /^Pets$/

  def handle_screen screen
    found = Hash.new{ |k,v| k[v] = [] }
    types = []
    already_moved = false
    cur = nil

    screen.slots.each do |slot|
      next if slot.empty?
      stack = slot.stack
      next unless stack.skyblock_id == "PET"
      next unless (lore = slot.stack.lore)

      already_moved ||= stack.dig('tag', 'origSlot')
      if lore['Click to despawn']
        cur = slot
      end
      type = lore.split(" ",2).first
      found[type] << slot
    end

    top = screen.y + screen.slots[0].y + 2
    left = screen.x + screen.slots[0].x

    unless already_moved
      found.keys.sort.each_with_index do |type, yi|
        found[type].each_with_index do |slot, xi|
          slot.data['xi'] = xi
          slot.data['yi'] = yi
          slot.data['newSlot'] ||= yi*9 + xi # XXX hor/vert mode
          if cur == slot
            slot.data['x'] = xi*9 + 8
            slot.data['y'] = yi*9 + top - 6
          end
        end
      end
    end

    if debug
      puts "[d] already_moved = #{already_moved}"
      puts "[d] cur = #{cur&.data}"
      found.each do |type, pets|
        puts "[d] #{type}:"
        pets.each do |pet|
          pdata = pet.data.dup
          pdata.delete('inventoryId')
          printf "    %-30s %s\n", pet.stack.display_name, pdata
        end
      end
    end

    debug = @debug
    MC.script(debug: debug) do
      unless already_moved
        # replace dark border slots with regular empty ones
        ((0..7).to_a + [9, 18, 27, 36, 45, 46]).each do |free_slot|
          copy_slot! src: 43, dst: free_slot
        end
        swapped_slots = {}
        found.values.flatten.each do |slot|
          src = swapped_slots[slot.index]   || slot.index
          dst = slot.newSlot

          swap_slots! src, dst

          swapped_slots[src] = dst
          swapped_slots[dst] = src
        end
        #lock_slot! -1, sync_id: screen.dig('handler', 'syncId')
      end
      ttl = debug ? 200 : 60
      found.keys.sort.each_with_index do |type, idx|
        puts "[d] y=#{top+idx*18}, type=#{type}" if debug
        add_hud_text! type, x: left-64, y: top+idx*18, ttl: ttl, color: 0x00ff00
      end
      if cur
        x = screen.x + cur.x + 8
        y = screen.y + cur.y + 1
        add_hud_text! "✔", x: x, y: y, ttl: ttl, color: 0x00ff00
      end
    end # MC.script
  end
end

if $0 == __FILE__
  require_relative '../common'
  h = PetsHelper.new
  h.debug = true
  loop do
    if MC.screen
      h.handle_screen MC.screen
      break
    end
    sleep 0.5
  end
end
