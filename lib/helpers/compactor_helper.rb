#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'base_helper'

class CompactorHelper < BaseHelper

  SCREEN_TITLE = /^Personal Compactor/

  def self.cache_fname
    File.join(MC.player.data_dir, "compactors.yml")
  end

  def self.read_cache
    YAML.load_file cache_fname
  rescue
    {}
  end

  def self.write_cache data
    File.write(cache_fname, data.to_yaml)
  end

  def handle screen
    return unless screen.title =~ SCREEN_TITLE
    return if @last_sync_id == screen.sync_id
    @last_sync_id = screen.sync_id

    cache = self.class.read_cache
    cache[screen.title] = []
    screen.nonplayer_slots.each do |slot|
      next if slot.empty?
      stack = slot.stack
      next unless stack.lore =~ /^Item:\s+(.+)$/
      dst_id = ItemDB.name2id($1)
      cache[screen.title] << dst_id
    end
    self.class.write_cache cache
  end
end
