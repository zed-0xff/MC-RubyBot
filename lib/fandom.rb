#!/usr/bin/env ruby
# frozen_string_literal: true
require 'open-uri'
require 'yaml'
require_relative 'skytime'

module Fandom
  CALENDAR_CACHE_FNAME = "data/farming_calendar.yml"

  def self.farming_calendar year = Skytime.now.year
    if @year == year && @calendar
      return @calendar
    end
    if File.exist?(CALENDAR_CACHE_FNAME)
      data = YAML::load_file(CALENDAR_CACHE_FNAME)
      if data['year'] == year
        @year = year
        @calendar = data['calendar'] 
        return @calendar
      end
    end
    @calendar = _parse_calendar year
    @year = year
    save_calendar!
    @calendar
  end

  def self.save_calendar! year = Skytime.now.year
    File.write(
      CALENDAR_CACHE_FNAME,
      {"year" => year, "calendar" => @calendar}.to_yaml
    )
  end

  def self._parse_calendar year
    calendar = {}
    url = "https://hypixel-skyblock.fandom.com/wiki/Jacob%27s_Farming_Contest/Events/Year_#{year}?action=raw"
    puts "[.] parsing #{url} .."
    data = URI.open(url).read
    data.scan(%r!\| {{Hl\|(.+)}} \|\| <span class="skydate-countdown txt-nowrap" data-skydate-start="(.+), 00:00" data-skydate-end="(.+), 23:59">!) do |veggies, dstart, dend|
      d = Skytime.parse(dstart)
      calendar[d.day_no] = {
        "day"   => d.day,
        "month" => d.month,
        "crops" => veggies.scan(/{{ID\|([^{}]+)}}/).map(&:first),
      }
    end
    calendar
  rescue OpenURI::HTTPError => e
    puts "[?] #{e}".red
    return {}
  end
end

if $0 == __FILE__
  pp Fandom.farming_calendar
end
