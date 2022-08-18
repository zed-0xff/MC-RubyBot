#!/usr/bin/env ruby
# frozen_string_literal: true

class EnchantHelper

  TARGET_SLOT = 19
  BOOK_SLOTS  = [12..16, 21..25, 30..34].map(&:to_a).flatten

  attr_accessor :debug

  def handle_screen screen
    target = screen.slots[TARGET_SLOT].stack
    p target if @debug
    return if target.empty?
    target_enchantments = target.dig('tag', 'ExtraAttributes', 'enchantments') || {}
    p target_enchantments if @debug
    found = {}
    BOOK_SLOTS.each do |slot_id|
      slot = screen.slots[slot_id]
      book = screen.slots[slot_id].stack
      next if book.empty?
      be = book.dig('tag', 'ExtraAttributes', 'enchantments')
      next if !be || be.empty?
      book_ench_key = be.keys.first
      level = target_enchantments[book_ench_key]
      found[slot] = level if level
    end
    p found if @debug
    return unless found.any?

    MC.script do
      found.each do |slot, level|
        x = screen.x + slot.x + 1
        y = screen.y + slot.y + 1

        add_hud_text! level, x: x, y: y, ttl: 20, color: 0x00ff00
      end
    end
  end

  def highlight_slots
    MC.script do
      screen.slots.each do |slot|
        next if slot.empty?
        x = screen.x + slot.x
        y = screen.y + slot.y

        add_hud_text! slot.id, x: x, y: y, ttl: 20, color: 0x00ff00
      end
    end
  end
end

if $0 == __FILE__
  require_relative 'common'
  eh = EnchantHelper.new
  eh.debug = true
  loop do
    if MC.screen
      eh.handle_screen MC.screen
    end
    sleep 1
  end
end
