#!/usr/bin/env ruby
require_relative '../common'

c = nil

loop do
  puts
  sheep = getMobs(radius: 40)['entities'].
    find_all{ |mob| mob['id'] == "minecraft:sheep" }

  [40, 20, 10, 5].each do |radius|
    c = sheep.find_all{ |s| distance(s['pos']) < radius }.
      group_by { |s| s.dig('nbt', 'Sheared') }.
      values.map(&:count)

    puts "[.] #{c} sheep in radius #{radius}"
  end

  if c != [18]
    sleep 0.5
    next
  end

  puts "[*] shearing!".green

  select_slot 1
  loop do
    rs = getMobs['entities'].
      find_all{ |mob| mob['id'] == "minecraft:sheep" && mob.dig('nbt', 'Sheared') == 0 }
#    break if rs.size != 18


    if rs.size == 0
      sleep 0.05
      next
    end
    #rs = sheep.find_all{ |s| reachable?(s) }
    puts "[.] #{rs.size} reachable unsheared sheep"
    rs.each do |s|
      look_at s['eyePos'], delay: 1
      sleep 0.05
      right_click!
      sleep 0.05
    end
  end

  sleep 0.5
  puts
end
