#!/usr/bin/env ruby
require_relative 'lib/common'

BLOCK_REACHABLE_DISTANCE  = 4.49
ENTITY_REACHABLE_DISTANCE = 2.99

uri = URI('http://127.0.0.1:9999/action')

script = [
  { command: "entities", expand: { x: 2.7, y: 2.7, z: 2.7 } },
  { command: "blocksRelative", expand: { x: 3.17, y: 3.17, z: 3.17 } },
]

MC.cache_ttl = 0.1

prev = nil
loop do
  res = Net::HTTP.post(uri, script.to_json)

  r = JSON.parse(res.body)
  entities = r.dig('entities').delete_if { |e| e['id'] != 'minecraft:cow' }

  blocks = r.dig('blocks').
    find_all{ |b| b['id'] == 'minecraft:sugar_cane' }

  if b=r.dig('player', 'looking_at', 'block')
    pos = r.dig('player', 'looking_at', 'pos')
    printf "[.] block: e=%.2f p=%.2f %s\n",
      distance(pos, r['player']['eyePos']),
      distance(pos, r['player']['pos']),
      pos.inspect
  end
#
#  blocks.each do |b|
#    printf "[.] block: e=%.2f p=%.2f %s\n",
#      distance(b['pos'], r['player']['eyePos']),
#      distance(b['pos'], r['player']['pos']),
#      b['pos'].inspect
#  end
#
  puts if entities.any?
  entities.each do |mob|
    printf "dist=%.2f e2e=%.2f e2b=%.2f %s\n",
    distance(mob['boundingCenter']),
    distance(player['eyePos'], mob['eyePos']),
    distance(player['eyePos'], mob['boundingCenter']),
    mob['uuid']
  end
#  sleep 0.1
end
