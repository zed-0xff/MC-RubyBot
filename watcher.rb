#!/usr/bin/env ruby
require_relative 'lib/common'

loop do
  m = MC.current_map
  p m
  if m && m != "Crystal Hollows"
    MC.chat! "#stop"
    break
  end
  sleep 5
  MC.invalidate_cache!
end
