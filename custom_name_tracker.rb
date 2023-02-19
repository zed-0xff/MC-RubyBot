#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'lib/common'

uri = URI('http://127.0.0.1:9999/action')

script = [
  { command: "entities", expand: {x: 40, y:40, z: 40} }
]

seen = {}

loop do
  res = Net::HTTP.post(uri, script.to_json)
  r = JSON.parse(res.body)

  r['entities'].each do |e|
    name = e['name']
    if name && name =~ /trackable|detected|dangered/i
      uuid = e['uuid']
      next if name =~ /Crypt/
      next if e['id'] == 'minecraft:armor_stand' && name =~ /^\d+$/
      next if e['id'] == 'minecraft:armor_stand' && name.tr(' ','') =~ /^✧\d+✧$/
      next if hp(e) == 0
      is_seen = true
      unless seen[uuid]
        is_seen = false
        seen[uuid] = name
        #p e
        printf "[*] %5.2f %s %s\n".green, distance(r['player']['pos'], e['pos']), uuid, name
      end
      unless is_seen
        MC.outline_entity! e['uuid']
        MC.look_at! e['pos']
      end
      msg = "%.2f to %s" % [distance(r['player']['pos'], e['pos']), name]
      MC.say! msg
    else
#      uuid = e['uuid']
#      name = e['id']
#      unless seen[uuid]
#        seen[uuid] = name
#        printf "[.] %5.2f %s %s\n".gray, distance(r['player']['pos'], e['pos']), uuid, name
#      end
    end
  end

  sleep 0.5
end
