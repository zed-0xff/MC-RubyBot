#!/usr/bin/env ruby
require_relative 'lib/common'

radius = ARGV.first.to_i
radius = 2 if radius == 0

script = [
  { command: "entities",
    stringArg: "BatEntity",
    expand: { x: radius, y: radius, z: radius },
  }
]

loop do
  r = MC.run_script!(script)
  if r['entities'].any?
    r['entities'].each do |e|
      MC.look_at! e['eyePos'], delay: 0
    end
    sleep 0.06
  else
    sleep 1
  end
end
