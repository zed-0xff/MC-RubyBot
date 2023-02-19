#!/usr/bin/env ruby
# frozen_string_literal: true
require 'json'
require 'uri'
require 'net/http'
require 'open-uri'

URL = 'http://127.0.0.1:9999/'
pos = JSON.parse(URI.open(URL).read).dig('player', 'pos')

uri = URI('http://127.0.0.1:9999/action')

R = 4

uuid = nil
loop do
  scan_script = [
    { command: "getMobs", box: {
      minX: pos['x']-R, minY: pos['y']-R, minZ: pos['z']-R,
      maxX: pos['x']+R, maxY: pos['y']+R, maxZ: pos['z']+R,
    }}
  ]

  res = Net::HTTP.post(uri, scan_script.to_json)
  r = JSON.parse(res.body)

  pos = r['player']['pos']
  mobs = r['mobs']
  mobs.each do |mob|
    p mob
    break
  end
  sleep 1
end
