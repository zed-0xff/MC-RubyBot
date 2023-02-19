#!/usr/bin/env ruby
# frozen_string_literal: true

class Skytime
  attr_accessor :year, :month, :day, :hour, :min

  T0 = 1560275700

  SKYMONTHS = {
     "ESP" =>  1,  "Early Spring" =>  1,
     "SP"  =>  2,  "Spring"       =>  2,
     "LSP" =>  3,  "Late Spring"  =>  3,
     "ESU" =>  4,  "Early Summer" =>  4,
     "SU"  =>  5,  "Summer"       =>  5,
     "LSU" =>  6,  "Late Summer"  =>  6,
     "EAU" =>  7,  "Early Autumn" =>  7,
     "AU"  =>  8,  "Autumn"       =>  8,
     "LAU" =>  9,  "Late Autumn"  =>  9,
     "EWI" => 10,  "Early Winter" => 10,
     "WI"  => 11,  "Winter"       => 11,
     "LWI" => 12,  "Late Winter"  => 12,
  }

  def initialize year, month=1, day=1, hour=0, min=0
    @year, @month, @day, @hour, @min = year, month, day, hour, min
  end

  def to_real_time
    ts = T0 + 
      (year-1)*7440*60 +
      (month-1)*620*60 +
      (day-1)*20*60 +
      (hour+min/60.0)/1.2*60
    Time.at(ts)
  end

  def day_no
    (month-1)*31 + day
  end

  def - other_time
    to_real_time - other_time.to_real_time
  end

  # "LWI 12, 226"
  def self.parse s
    case s
    when /^([A-Za-z ]+) (\d+)$/
      new(now.year, SKYMONTHS[$1], $2.to_i)
    when /^([A-Za-z ]+) (\d+), (\d+)$/
      new($3.to_i, SKYMONTHS[$1], $2.to_i)
    else
      raise "unknown skytime format: #{s.inspect}"
    end
  end

  def self.now
    at(Time.now.to_i)
  end

  # https://hypixel-skyblock.fandom.com/wiki/Time
  # https://hypixel-skyblock.fandom.com/wiki/Module:Skydate
  def self.at t
    dm = (t-T0).to_i / 60.0
    year, dm = dm.divmod(7440)
    month, dm = dm.divmod(620)
    day, dm = dm.divmod(20)
    hour = (dm * 1.2).to_i
    min = ((dm * 1.2).modulo(1)*60).to_i
    new(year+1, month+1, day+1, hour, min)
  end
end

if $0 == __FILE__
  t = Skytime.now
  p t
  p t.to_real_time
end
