#!/usr/bin/env ruby
require_relative 'enchant'

a = [
  [-136, 37],
  [ -89, 43],
  [ -45, 36],
  [   2, 43],
  [  47, 36],
  [  92, 43],
  [ 134, 37],
  [ 180, 43],
]

b = [
  [-136, -55],
  [ -89, -55],
  [ -45, -55],
  [   2, -55],
  [  47, -55],
  [  92, -55],
  [ 134, -55],
  [ 180, -55],
]

loop do
  if MC.player.inventory.full?
    enchant_inventory!
  end
  20.times do
    a.each do |yaw, pitch|
      MC.set_pitch_yaw! pitch: pitch, yaw: yaw
      sleep 0.25
    end
  end
  b.each do |yaw, pitch|
    MC.set_pitch_yaw! pitch: pitch, yaw: yaw
    sleep 0.5
  end
end
