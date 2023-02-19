#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'lib/common'

uri = URI('http://127.0.0.1:9999/action')

script = [
  { 
    command: "entities",
    stringArg: "OtherClientPlayerEntity",
    expand: {x: 40, y:40, z: 40}
  }
]

seen = {}

loop do
  res = Net::HTTP.post(uri, script.to_json)
  r = JSON.parse(res.body)

  r['entities'].each do |e|
    uuid = e['uuid']
    name = e['name']
    unless seen[uuid]
      seen[uuid] = name
      attrs = e.dig('nbt', 'Attributes')
      if attrs && attrs.size != 4
        say "§c§l#{name} #{attrs.size}"
        p attrs
      else
        puts "[-] #{name}"
        p attrs
      end
    end
  end

  sleep 0.2
end
