#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'base_helper'

class CalendarHelper < BaseHelper

  SCREEN_TITLE = /^([A-Za-z ]+), Year (\d+)$/

  def handle screen
    return unless screen.title =~ SCREEN_TITLE
    month = $1
    year = $2
    updated = false
    screen.nonplayer_slots.each do |slot|
      next if slot.empty?
      stack = slot.stack
      next if stack.is_a?(:paper)
      next if !stack.lore || !stack.lore["Farming Contest"]
      day = stack.count
      # "12:00am-11:59pm:   Jacob's Farming Contest  ( 06h 04m 55s )\n○  Cactus\n○  Carrot\n○  Nether Wart"
      crops = stack.lore.scan(/○\s+(\w+)/).flatten
      d = Skytime.parse("#{month} #{day}, #{year}")

      Fandom.farming_calendar[d.day_no] = {
        "day"   => d.day,
        "month" => d.month,
        "crops" => crops,
      }
      updated = true
    end
    Fandom.save_calendar! if updated
  end
end
