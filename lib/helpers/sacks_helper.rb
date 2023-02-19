# frozen_string_literal: true

require_relative 'base_helper'

class SacksHelper < BaseHelper

  SCREEN_TITLE = / Sack$/

  def initialize
  end

  def handle_screen screen
    r = []
    screen.nonplayer_slots.each do |slot|
      next if slot.empty?
      lore = slot.stack&.lore
      next if !lore
      next unless lore =~ /Stored:\s+([\d,]+)[^\d]\//

      stored = $1.tr(",","").to_i
      next if stored == 0

      x = screen.x + slot.x + 1
      y = screen.y + slot.y + 1
      r << [x, y, stored]
    end
    if r.any?
      MC.script do
        r.each do |x, y, stored|
          storeh = stored.to_s(16)
          case stored
          when 1..15
            add_hud_text! storeh, x: x+9, y: y, ttl: HUD_TEXT_TTL, color: 0xffffff
          when 16..159
            add_hud_text! storeh, x: x+3, y: y, ttl: HUD_TEXT_TTL, color: 0xffffff
          when 160..(15*160)
            add_hud_text! (stored/160).to_s(16), x: x+9, y: y, ttl: HUD_TEXT_TTL, color: 0x00ff00
          else
            add_hud_text! (stored/160).to_s(16), x: x+3, y: y, ttl: HUD_TEXT_TTL, color: 0x00ff00
          end
        end
      end
    end
  end
end
