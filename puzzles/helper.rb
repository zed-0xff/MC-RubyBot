#!/usr/bin/env ruby
require_relative '../lib/common'
require 'digest/md5'

def save_screen screen, fname: nil
  return if fname && File.exist?(fname)

  data = screen.data.to_json
  hash = Digest::MD5.hexdigest(data)

  screen.data['timestamp'] ||= Time.now.to_f
  data = screen.data.to_json

  @fname = fname || "screens/#{screen.title.split.first}_#{Time.now.strftime("%d_%H_%M_%S")}_#{hash}.json"
  unless File.exist?(@fname)
    File.write(@fname, data) 
  end
end

def pick_color colors, item_id
  COLOR_ALIASES.each do |k,v|
    return v if item_id[k] && colors.include?(v)
  end
  colors.find { |c| item_id[c] } || colors.random
end

@screens = {}
@id2color = {}
@superpairs_codes = {}

def process_screen screen, fname: nil
  return if !screen || !screen['slots']

  save_screen screen, fname: fname

  @screens[screen.title] ||= Hash.new{ |h,k| h[k] = {} }
  slots = @screens[screen.title]
  codes = {}

  screen.slots.each do |slot|
    next if slot['inventoryId'] == 'player'
    inventory = screen['inventories'][slot['inventoryId']]

    case screen.title
    when /Superpairs \(/ #, /Ender/ # test
      codes = @superpairs_codes
      # hide timer / clicks count
      next if [4, 49].include?(slot.id)
      # do not overwrite hidden slots
      if slot.empty? || slot.stack.display_name == "?" || slot.stack.display_name =~ /Click any button/
        slots[slot.y][slot.x] ||= nil
      else
        next if slots[slot.y][slot.x] && slot.stack.id =~ /(_glass|_glass_pane|barrier|air)$/
        #id = slot.stack.display_name(color: true) + " #{slot.stack.id}"
        id = slot.stack.id
#        puts slot.stack.display_name(color: true)
#        puts slot.stack.id
#        p slot.stack.data
#        puts
        slots[slot.y][slot.x] = slot.stack.data.to_json
      end
    when /Sequencer \(/
      id = "%2d" % slot.stack.size
      slots[slot.y][slot.x] = slot.empty? ? nil : id
      items[id] = id
    else
      id = !slot.empty? && (slot.stack.display_name(color: true) || slot.stack.id)
      slots[slot.y][slot.x] = slot.empty? ? nil : id
    end
  end

  srand(31337)

  colors = []
  code = nil
  items = {}
  result = ""
  slots.each do |y, row|
    row.each do |x, id|
      code = items[id] ||
        case id
        when nil, '  ', /(_glass|_glass_pane|barrier|air)$/, /Click a second/
          '  '
        else
          if id =~ /^(\e\[\d+;\d+m)(.+)(\e\[0m)?$/
            # already colorized
            prefix, id, postfix = $1, $2, $3
            a = id.sub('minecraft:','').split(/[_ ]/, 2)
            code = (a.size == 1 ? a[0][0,2] : a[0][0] + a[1][0]).upcase
            code = prefix + code + "\e\[0m"
          elsif id =~ /^\{.+\}$/
            # json
            color = @id2color[id] || get_color(JSON.parse(id)['id'])
            if !color
              if colors.empty?
                colors = COLORS.dup.shuffle
              end
              color = colors.delete(pick_color(colors, id))
              @id2color[id] = color
            end
            code = codes[id] || (('A'.ord + codes.size).chr * 2)
            codes[id] = code
            code = code.send(color)
          else
            a = id.sub('minecraft:','').split(/[_ ]/, 2)
            code = (a.size == 1 ? a[0][0,2] : a[0][0] + a[1][0]).upcase
            color = @id2color[id]
            if !color
              if colors.empty?
                colors = COLORS.dup.shuffle
              end
              color = colors.delete(pick_color(colors, id))
            end
            @id2color[id] = color
            code = code.send(color)
          end
          items[id] = code
        end
      result << code << "  "
      MC.add_hud_text! ansi2mc(code), x: screen.x+x+1, y: screen.y+y+1, ttl: 120
    end
    result << "\n"
  end

  legend = ''
  items.sort_by{ |id, code| codes[id] }.each do |id, code|
    x = code.dup
    x[7,2] =
      if id =~ /^\{.+\}$/
        stack = ItemStack.new( JSON.parse(id) )
        stack.display_name.ljust(25) + " (#{stack.id})".gray
      else
        id.sub('minecraft:','')
      end
    legend << code << "  " << x << "\n"
  end

  legend + "\n" + result
end

prev = nil

MC.cache_ttl = 0.01

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
  loop do
    screen = MC.screen
    r = process_screen screen
    if r && r != prev
      printf "===== %-30s (#@fname)\n".gray, screen.title
      puts r
      prev = r
    end
  end
end

