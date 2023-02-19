#!/usr/bin/env ruby
require_relative 'lib/common'

MC.cache_ttl = 0

def record
  prev_state = nil
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  loop do
    t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    s = status
    p = status['player']
    input = s['input']
    input.each do |key, info|
      info.delete 'age'
    end
#    state = [0, p['pos'], p['pitch'], p['yaw'], input]
    input.delete_if { |k,v| k =~ /keyboard/ }
    input.delete 'mouse.x'
    input.delete 'mouse.y'
    state = [0, input]
    if state != prev_state
      prev_state = state
      state[0] = (t-t0).round(3)
      puts state.to_json
      state[0] = 0
    end
  end
rescue Interrupt
end

record
