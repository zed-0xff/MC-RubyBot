#!/usr/bin/env ruby
require_relative 'lib/common'

loop do
  if MC.player.current_tool.is_a?("SNOW_BLASTER")
    MC.interact_item!
  end
end
