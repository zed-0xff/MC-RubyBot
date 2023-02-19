#!/usr/bin/env ruby
require_relative 'lib/common'

MC.cache_ttl = 0

def replay script
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  script.split("\n").each do |line|
    state = JSON.parse(line)
    t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    dt_our = t-t0
    dt_req, pos, pitch, yaw = state
    if dt_our < dt_req
      sleep(dt_our-dt_req)
    end
    set_pitch_yaw pitch: pitch, yaw: yaw
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
rescue Interrupt
end

replay File.read(ARGV[0])
