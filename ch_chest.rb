#!/usr/bin/env ruby
require_relative 'lib/common'
require 'json'
require 'uri'
require 'net/http'
#require 'open-uri'
require 'awesome_print'

#URL = 'http://127.0.0.1:9999/'
#pos = JSON.parse(URI.open(URL).read).dig('player', 'pos')

uri = URI('http://127.0.0.1:9999/action')

r = 2

#pos = { 'x' => 120, 'y' => 72, 'z' => -228 }

script = [
#  { command: "attack" }
  #{ command: "lookAt", target: { "x": rand(200)-100, "y": -60, "z": rand(200)-100 }, delay: (10 + rand(20))}
#  { command: "outlineEntity", stringArg: "65cb8af7-893b-eaf2-ea8f-46d483208da3", boolArg: true },
#  { command: "sleep", delay: 2000 },
#  { command: "key", stringArg: "key.keyboard.left.control", delay: 50 },
#  { command: "addTeam", stringArg: "test" },
#  { command: "breakBlock", boolArg: true },
  #{ command: "ai", target: { "x": -2, "y": 70, "z": -75 } }
#  { command: "chat", stringArg: "/sacks" }
# { command: "say", stringArg: "§c§lfoo§fbar" },
  #{ command: "setAutoJump", boolArg: true }
#  { command: "playSound", stringArg: "entity.shulker.ambient", floatArg: 1.0 },
#  { command: "playSound", stringArg: "", floatArg: 1.0 },
#  { command: "sleep", delay: 500 },
  #{ command: "registerCommand", stringArg: "foo" },
  #{ command: "registerCommand", stringArg: "stop" },
#  { command: "getMobs", box: {
#    minX: pos['x']-r, minY: pos['y']-r, minZ: pos['z']-r,
#    maxX: pos['x']+r, maxY: pos['y']+r, maxZ: pos['z']+r,
#  }}
  #{ command: "lookAt", target: { "x": -301 + rand(3), "y": 80, "z": rand(-57) + rand(3) } }
  #{ command: "lookAt", target: { "x": -303 + rand()*3, "y": 80, "z": -58 + rand()*3 } }
#  { command: "entities", expand: { x: 10, y: 10, z: 10 } },
#  { command: "dropSelectedItem", boolArg: true },

# XXX WORKS!!!!!!!!!!!!!!
#  { command: "clickSlot", intArg: 9, intArg2: 0, stringArg: "SWAP" },

#  { command: "clickSlot", intArg: 10, intArg2: 0, stringArg: "PICKUP" },
#  { command: "swapSlotWithHotbar", intArg: 16 },
#  { command: "lockCursor", boolArg: false }
#  { command: "getTeams" },
#  { command: "setTeamPrefix", stringArg: "team_1", stringArg2: "A" },
#  { command: "setTeamSuffix", stringArg: "team_1", stringArg2: "" },
#  { command: "getMods" }
#  { command: "HUD.addText", stringArg: "XXX", x: 10, y: 10, color: 0xffffff, ttl: 1000 },
#  { command: "Screen.setSlotXY", intArg: 10, intArg2: 37 }
#  { command: "Screen.copySlot", intArg: 10, intArg2: 37 },
#  { command: "Screen.swapSlots", intArg: 19, intArg2: 15 },
#  { command: "Screen.swapSlots", intArg: 36, intArg2: 19 },
#  { command: "getSounds" }
#  { command: "hideOtherPlayers", boolArg: false }
#  { command: "Screen.setSlotIndex", intArg: 37, intArg2: 10 },
#  { command: "setOverlayMessage", stringArg: "foo", intArg: 50 }
#  { command: "say", stringArg: "hi" },
#  { command: "sleep", delay: 10000 }
#  { command: "blocksRelative", expand: { x: 2, y: 2, z: 2 } }
#  { command: "clearExtras" },
#  { command: "hideEntity", stringArg: "a98b49b7-ba29-27b8-b6be-f0b238d11ee2" }
#  { command: "setEntityExtra", stringArg: "f38fe6a2-f4e7-26a4-ae0d-33658e977562", intArg: 2, longArg: 22 }
#  { command: "clickScreen", x: 190, y: 150 }
#  { command: "pickFromInventory", intArg: 9 }
#  { command: "clickSlot", intArg: 16, intArg2: 7, stringArg: "SWAP" },
#  { command: "clickSlot", intArg: 9, intArg2: 7, stringArg: "SWAP" },
#  { command: "interactBlock" },
#  { command: "showInventory" },
#  { command: "sleep", delay: 1000 },
#  { command: "clickSlot", intArg: 9, intArg2: 0, stringArg: "QUICK_MOVE" }
#  { command: "closeHandledScreen" },
#  { command: "key", stringArg: "key.mouse.left", delay: 500 },
#  { command: "startBreakingBlock" },
#  { command: "sleep", delay: 1000 },
#  { command: "stopBreakingBlock" },
#  { command: "setPitchYaw", delay: 100 },
#  { command: "travel", target: { x: 0, y: 0, z: 10 } },
#  { command: "raytrace" }
#  { command: "selectSlot", intArg: 0 },
#  { command: "interactItem" },
#  { command: "selectSlot", intArg: 1 },
#  { command: "interactItem" },
#  { command: "blocks", expand: {x: 2, y:2, z: 2} }
#    minX: pos['x']-r, minY: pos['y']-[3, r].min,   minZ: pos['z']-r,
#    maxX: pos['x']+r, maxY: (pos['y']+[1, r].min), maxZ: pos['z']+r,
#  }}
#  { command: "Screen.enableSyncing", boolArg: true },
#  { command: "clickScreenSlot", intArg: 57, intArg2: 0, stringArg: "PICKUP" },
#  { command: "clickScreenSlot", intArg: 3, intArg2: 0, stringArg: "PICKUP" },
#  { command: "messages", stringArg: "lick" },
  { command: "particles" }
]

def add_particles x,y,z
  d = 0.15
  [
    { command: "addParticle", target: { x: x, y: y, z: z }, offset: { x:  d, y: 0, z:  0 } },
    { command: "addParticle", target: { x: x, y: y, z: z }, offset: { x: -d, y: 0, z:  0 } },
    { command: "addParticle", target: { x: x, y: y, z: z }, offset: { x:  0, y: 0, z:  d } },
    { command: "addParticle", target: { x: x, y: y, z: z }, offset: { x:  0, y: 0, z: -d } },
    { command: "addParticle", target: { x: x, y: y, z: z }, offset: { x:  d, y: 0, z:  d } },
    { command: "addParticle", target: { x: x, y: y, z: z }, offset: { x: -d, y: 0, z: -d } },
    { command: "addParticle", target: { x: x, y: y, z: z }, offset: { x: -d, y: 0, z:  d } },
    { command: "addParticle", target: { x: x, y: y, z: z }, offset: { x:  d, y: 0, z: -d } },
  ]
end

index = 0
loop do
  script = [{ command: "particles", intArg: index }]
  res = Net::HTTP.post(uri, script.to_json)
  script = []
  JSON.parse(res.body)['particles'].each do |p|
    index = [p['index'], index].max
    if p['effect'] == 'minecraft:crit'
      pos = Pos.new(p['x'], p['y'], p['z'])
      MC.look_at! pos
    end
  end
  sleep 0.3
end

loop do
  res = Net::HTTP.post(uri, script.to_json)
  puts res.body
  #p JSON.parse(res.body)['particles']
  break
  sleep 1
end
