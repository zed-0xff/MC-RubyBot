#!/usr/bin/env ruby
require_relative '../autoattack'
require 'digest/md5'

COLORS = %w(gray red green yellow blue purple cyan white) +
  %w(redish greenish yellowish blueish purpleish cyanish whiteish)

ALIASES = {
  "light_blue" => "cyan",
  "lime"    => "green",
  "diamond" => "cyan",
  "emerald" => "green",
  "gold"    => "yellow",
  "pink"    => "redish",
}

def save_screen screen
  data = screen.to_json
  hash = Digest::MD5.hexdigest(data)
  @fname = "screens/#{hash}.json"
  unless File.exist?(@fname)
    File.write(@fname, data) 
  end
end

def pick_color colors, item_id
  ALIASES.each do |k,v|
    return v if item_id[k] && colors.include?(v)
  end
  colors.find { |c| item_id[c] } || colors.random
end

def process_screen screen
  return if !screen || !screen['slots']

#  save_screen screen

  slots = Hash.new{ |h,k| h[k] = {} }
  screen.slots.each do |slot|

    MC.add_hud_text! slot.id, x: screen.x + slot['x'], y: screen.y + slot['y'], color: 0x00ff00, ttl: 900

    next if slot['inventoryId'] == 'player'
    if (stack = slot.stack)
#      next if stack.to_s =~ /Round: |Timer: |Remember the pattern/
      slots[slot.y][slot.x] = 
        if stack['id'] =~ /(glass_pane|arrow|barrier|air)$/
          '  '
        else
          sprintf("%02d", slot.index)
        end
    end
  end

  srand(31337)

  colors = []
  code = nil
  items = {}
  result = ""
  slots.values.each do |row|
    row.values.each do |id|
      code = 
        if id =~ /(glass_pane|arrow|barrier|air)$/
          '  '
        elsif items[id]
          items[id]
        else
          code = id
          if colors.empty?
            colors = COLORS.dup.shuffle
          end
          color = colors.delete(pick_color(colors, id))
          code = code.send(color)
          items[id] = code
        end
      result << code << "  "
    end
    result << "\n"
  end

  legend = ''
  items.each do |id, code|
    x = code.dup
    x[7,2] = id.sub('minecraft:','')
    legend << code << "  " << x << "\n"
  end

  result
end

prev = nil

if ARGV.any?
  ARGV.each do |fname|
    screen = Screen.new JSON.parse(File.read fname)
    r = process_screen screen
    if r && r != prev
      printf "===== %-30s (#@fname)\n".gray, screen.title
      puts r
      prev = r
    end
  end
else
  if (screen = status['screen'])
    r = process_screen MC.screen
    if r && r != prev
      printf "===== %-20s  %s\n".gray, MC.screen.title, @fname
      puts r
      prev = r
    end
  end
  sleep 0.1
end

