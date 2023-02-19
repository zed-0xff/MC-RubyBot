#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'base_helper'

class EnchantHelper < BaseHelper

  SCREEN_TITLE = /^Enchant Item$/

  TARGET_SLOT = 19
  BOOK_SLOTS  = [12..16, 21..25, 30..34].map(&:to_a).flatten
  MAX_LEVELS  = Hash.new(5).merge!({
    experience:   3,
    fire_aspect:  2,
    first_strike: 4,
    fortune:      3,
    impaling:     3,
    life_steal:   3,
    looting:      3,
    scavenger:    3,
    depth_strider:3,
    thorns:       3, # TODO: autolearn max level
    respiration:  3,
    aqua_affinity:1,
    knockback:    2,
    syphon:       3,
  })

  CONFLICTING = {
    first_strike: [:triple_strike],
    sharpness:    [:smite, :bane_of_arthropods],
    thunderbolt:  [:thunderlord],
    syphon:       [:life_steal],
    frost_walker: [:depth_strider],
    protection:   [:projectile_protection, :blast_protection, :fire_protection],
    prosecute:    [:execute],
    titan_killer: [:giant_killer],
  }

  CONFLICTING.keys.each do |k|
    a = CONFLICTING[k]
    a.each do |k2|
      CONFLICTING[k2] = a - [k2] + [k]
    end
  end

  attr_accessor :debug

  def handle_screen screen
    target = screen.slots[TARGET_SLOT].stack
    p target if @debug
    return if target.nil? || target.empty?
    target_enchantments = target.dig('tag', 'ExtraAttributes', 'enchantments') || {}
    target_enchantments.transform_keys!{ |k| k.downcase.to_sym }
    p target_enchantments if @debug
    found = {}
    BOOK_SLOTS.each do |slot_id|
      slot = screen.slots[slot_id]
      book = screen.slots[slot_id].stack
      next if book.empty?
      ench_key = book.display_name.downcase.tr(' -', '_').to_sym
      if (level=target_enchantments[ench_key])
        max = MAX_LEVELS[ench_key]
        found[slot] = (max && level >= max) ? "✔" : "§e§l#{level}"
      elsif CONFLICTING[ench_key]&.any?{ |k| target_enchantments[k] }
        found[slot] = "x"
      end
    end
    p found if @debug
    return unless found.any?

    MC.script do
      found.each do |slot, l|
        x = screen.x + slot.x + 8
        y = screen.y + slot.y + 1

        # blink for attention
        next if l['§e'] && (MC.last_tick%20) <= 10

        add_hud_text! l, x: x, y: y, ttl: HUD_TEXT_TTL, color: 0x00ff00
      end
    end
  end

  def highlight_slots
    MC.script do
      screen.slots.each do |slot|
        next if slot.empty?
        x = screen.x + slot.x
        y = screen.y + slot.y

        add_hud_text! slot.id, x: x, y: y, ttl: HUD_TEXT_TTL, color: 0x00ff00
      end
    end
  end
end

if $0 == __FILE__
  require_relative '../common'
  eh = EnchantHelper.new
  eh.debug = true
  loop do
    if MC.screen
      eh.handle_screen MC.screen
      break
    end
    sleep 1
  end
end
