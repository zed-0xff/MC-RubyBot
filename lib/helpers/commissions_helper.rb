#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base_helper'

class CommissionsHelper < BaseHelper
  SCREEN_TITLE = /^Commissions$/

  def handle_screen screen
    lore = screen.slots[30].stack.lore
    if lore =~ /(Progress to milestone \w+:) .+$\n(\d+ \/ \d+)/
      progress = [$1, $2].join(' ').green
      if @prev_progress != progress
        MC.say! "[.] #{progress}"
        @prev_progress = progress
      end
    end
    screen.nonplayer_slots.each do |slot|
      next if slot.empty?
      if slot.stack.is_a?(:writable_book)
        if slot.stack.lore =~ /^COMPLETED$/
          slot.click!
          sleep 0.2
        end
      end
    end
  end
end
