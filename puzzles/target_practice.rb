#!/usr/bin/env ruby
require_relative '../lib/common'

$stdout.sync = true

MC.cache_ttl = 0

pos = {
  "x": 0.753457582019996,
  "y": 62,
  "z": -144.68016041749746
}

@coords = [
  [-2.5499673, -56.849],
  [6.150035, -88.199104],
  [13.950033, -120.74921],
  [-1.9499706, -149.99913],
  [-2.84997, 178.80092],
  [7.9500327, 171.60078],
  [-1.3499694, 153.30063],
  [11.850028, 122.25073],
  [-5.999975, 114.45079],
  [3.9000258, 98.10083],
  [-1.499975, 89.40103],
  [2.250025, 66.30084],
  [-6.8999767, 60.301025],
  [-24.149971, 46.951263],
  [2.1000297, 5.701233],
  [-1.6499707, -2.698578],
]

def capture_coords
  prevstate = 0
  loop do
    state = MC.status.dig('input', 'key.mouse.left', 'state')
    if prevstate != state && state == 1
      puts  [player.pitch, player.yaw].inspect + ","
    end
    prevstate = state
  end
end

def shoot!
  @coords.each_with_index do |a, idx|
    pitch, yaw = a
    printf "[.] #%d: %.3f %.3f\n", idx, pitch, yaw
    MC.set_pitch_yaw! pitch: pitch, yaw: yaw, delay: 5
    sleep 0.2
    MC.interact_item!
    sleep 0.2
  end
end

if ARGV.first == "record"
  capture_coords
else
  shoot!
end
