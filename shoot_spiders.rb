#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'autoattack'

SHOOT_MOBS = [
  "minecraft:spider",
  "minecraft:skeleton",
]

loop do
  r = getMobs(radius: 12, radiusY: 2)
  r['mobs'].each do |mob|
    next unless SHOOT_MOBS.include?(mob['id'])
    puts shortstatus(mob)
    look_at(Pos[mob['eyePos']] + Pos[0, 0.3 + rand()/5, 0])
    sleep(0.1 + rand()/4)
    select_tool /SHORTBOW/
    MC.interact_item!
    sleep(0.2 + rand()/2)
  end
  sleep(0.4 + rand()*5)
  if rand(10) == 1
    sleep(10)
  end
end
