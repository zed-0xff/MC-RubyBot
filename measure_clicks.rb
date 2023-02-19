#!/usr/bin/env ruby
require_relative 'lib/common'

MC.cache_ttl = 0

prevstate = {}
loop do
  m = MC.status['input']['key.mouse.left']
  if m['state'] != prevstate['state']
    p prevstate
    prevstate = m
  end
end
