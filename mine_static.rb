#!/usr/bin/env ruby
require_relative 'autoattack'
require_relative 'enchant'

MC.cache_ttl = [0.1, MC.cache_ttl].min

@unreachables = Hash.new(0)
@unreach_player_pos = nil

def unreachable pos
  if @unreach_player_pos != status['player']['pos']
#    puts "\n[d] clearing unreachables"
    @unreach_player_pos = status['player']['pos']
    @unreachables.clear
  end
  @unreachables[pos] += 1
  $stdout << "unreachable #{@unreachables[pos]}"
end

NONMINEABLE = %w'minecraft:bedrock minecraft:polished_andesite minecraft:dirt minecraft:red_carpet'

def is_ore?(x)
  return false unless x

  if ARGV.any?
    return ARGV.include?(x.sub('minecraft:',''))
  else
    return false if x =~ /birch|spruce|oak|jungle|acacia/
    !NONMINEABLE.include?(x)
  end
#  x && x['_ore']
  ORE_PRIORITIES.keys.include?(x)
end

def reachable? xpos
  @unreachables[xpos] < 2 && distance(xpos) < (BLOCK_REACHABLE_DISTANCE+0.5)
end

SAVE_LAST_ORES = 2
@last_ores = []

BLOCK_MINE_TIMEOUT = 2
TITANIUM_MINE_TIMEOUT = 6

ORE_PRIORITIES = Hash.new(100) # default
ORE_PRIORITIES["minecraft:polished_diorite"]  = 10 # titanium
ORE_PRIORITIES["minecraft:red_stained_glass"] = 10 # ruby
ORE_PRIORITIES["minecraft:red_stained_glass_pane"] = 10 # ruby
ORE_PRIORITIES["minecraft:coal_block"]        = 10
ORE_PRIORITIES["minecraft:iron_ore"]          = 10

ORE_PRIORITIES["minecraft:gold_ore"]          = 11
ORE_PRIORITIES["minecraft:emerald_ore"]       = 12
ORE_PRIORITIES["minecraft:redstone_ore"]      = 12
ORE_PRIORITIES["minecraft:diamond_ore"]       = 12

ORE_PRIORITIES["minecraft:glowstone"]         = 14
ORE_PRIORITIES["minecraft:gold_block"]        = 14

ORE_PRIORITIES["minecraft:lapis_ore"]         = 14

ORE_PRIORITIES["minecraft:cyan_terracotta"]   = 14 # gold/mithril (fastest exp gain)
ORE_PRIORITIES["minecraft:gray_wool"]         = 14 # gold/mithril

ORE_PRIORITIES["minecraft:prismarine_bricks"] = 15
ORE_PRIORITIES["minecraft:dark_prismarine"]   = 15
ORE_PRIORITIES["minecraft:prismarine"]        = 15
ORE_PRIORITIES["minecraft:light_blue_wool"]   = 15 # long

ORE_PRIORITIES["minecraft:coal_ore"]          = 16

ORE_PRIORITIES["minecraft:ice"]               = 35

#ORE_PRIORITIES["minecraft:stone"]             = 50
#ORE_PRIORITIES["minecraft:cobblestone"]       = 50

if MC.current_map == 'Crystal Hollows'
  config = YAML::load_file 'config.yml'
  blocks = config.dig('rules', 'crystal_hollows', 'blocks')
  blocks -= ['stone']
  blocks.each do |block|
    ORE_PRIORITIES["minecraft:#{block}"] = 5
  end
  ORE_PRIORITIES["minecraft:cobblestone"] = 6
end

ORE_NAMES = {
  "minecraft:cyan_terracotta"   => "mithril",
  "minecraft:polished_diorite"  => "titanium",
  "minecraft:dark_prismarine"   => "mithril",
  "minecraft:gray_wool"         => "mithril",
  "minecraft:light_blue_wool"   => "mithril",
  "minecraft:prismarine"        => "mithril",
  "minecraft:prismarine_bricks" => "mithril",
  "minecraft:sea_lantern"       => "mithril", # questionable
}

@tstart = Time.now
@stats = Hash.new(0)

def format_stats
  @stats.keys.sort.map do |ore_name|
    count_str = "%d" % @stats[ore_name]
    if (color = get_color(ore_name))
      count_str.send(color)
    else
      count_str
    end
  end.join(",")
end

@prev_formatted_dt = nil
@history_str = ""

def respect_player_and_attack_mobs
  respect_player

#  mobs = getMobs(reachable: true)['entities']
#  if mobs.any? #|| player.hp < prev_hp #{ |mob| hp(mob) != max_hp(mob) }
#    select_slot 0
#    attack_nearest timeout: 2
#  end
end

def look_at_block pos, delay: nil
  r = MC.look_at_block! pos.to_h, delay: delay
  r['lookAtBlock'] ? r.dig('player', 'looking_at') : nil
end

def mine_static!
  respect_player_and_attack_mobs

  if MC.player.inventory.full?
#    release_key('key.mouse.left')
    sleep 0.1
    begin
      #enchant_inventory!
      enchant_all! filter: 'MINING'
    rescue => e
      puts "[!] #{e}".red
      sleep 1
      return
    ensure
      MC.close_screen!
    end
    sleep 0.2
  end

#  release_key('key.mouse.left') # release helps to reset stuck state?
#  press_key('key.mouse.left')

  ores = scan(radius: BLOCK_REACHABLE_DISTANCE)['blocks'].
    find_all{ |x| is_ore?(x['id']) }.
    sort_by{ |x|
      add =
        if @prev_block
          distance(@prev_block['pos'], x['pos'])/100.0
        else
          rand()
        end
      ORE_PRIORITIES[x['id']] + add
    }.
    delete_if{ |x| !reachable?(x['pos']) }
#    delete_if{ |x| @last_ores.any?{ |l| x['pos']['x'] == l['x'] && x['pos']['z'] == l['z'] } }.
#    shuffle

  if ores.empty? || MC.player.speed != 0
    release_key('key.mouse.left')
    @history_str << "."
    sleep(1 + rand()*5)
#    press_key('key.mouse.left')
  else
    prev_prio = nil
    # only 2 to force rescan after each mined block to optimize mining prioritized ores
    ores[0,2].each do |block|
      respect_player_and_attack_mobs
      break if MC.player.inventory.full?

      prio = ORE_PRIORITIES[block['id']].to_i # cut random part!
      if prev_prio && prio > prev_prio
        #puts "[!] prio reset (#{prio} > #{prev_prio})"
        # always mine top prios
        break
      end
      prev_prio = prio
      if ARGV.any?{ |x| x == 'sand' }
        select_tool /SPADE|SHOVEL/
      elsif ARGV.any?{ |x| x['_log'] }
        select_tool /_AXE/
      else
        select_tool /PICKAXE|DRILL/
      end
#      release_key('key.mouse.left')
#      press_key('key.mouse.left')

      if (r = look_at_block(block['pos']))
        MC.break_block!
      else
        @unreachables[block['pos']] += 1
        next
      end

      dt = Time.now - @tstart
      formatted_dt = "%02d:%02d" % [dt/3600, (dt/60)%60]
      if @prev_formatted_dt != formatted_dt
        puts if @prev_formatted_dt
        @prev_formatted_dt = formatted_dt
        @history_str = ""
      end

      ore_name = ORE_NAMES[block['id']] || block['id'].sub("minecraft:","").sub(/_(ore|block)$/,'')
      printf "\r[.] %02d:%02d [%s] [%d,%d,%d] %s%s   ",
        dt/3600, (dt/60)%60,
        format_stats,
        block['pos']['x'], block['pos']['y'], block['pos']['z'],
        @history_str,
        colorize(ore_name)

#      @last_ores << block['pos'].dup
#      @last_ores.last['y'] = 0
#      @last_ores.uniq!
#      @last_ores.shift if @last_ores.size > SAVE_LAST_ORES

      #r = look_at_block(Pos.new(block['pos']) + Pos.new(0.4+rand()/5, 0, 0.4+rand()/5), delay: 10)
      #r = look_at_block(block['pos'])

      #pos = Pos.new(block['pos']) + Pos.new(0.4+rand()/5, 0, 0.4+rand()/5)
      r = look_at_block(block['pos'])
      t0 = Time.now

      block_mine_timeout = (ore_name =~ /mithril|titanium|glass/i) ? TITANIUM_MINE_TIMEOUT : BLOCK_MINE_TIMEOUT
      dt = 0
      step = 0
      was = false
      #puts "[1] #{r['pos']}"
      while r && (is_ore?(r.dig('block', 'id'))) && ((dt=(Time.now - t0)) < block_mine_timeout)
        break if player_acted?
        if step > 3 && MC.player.dig('isBreakingBlock') == false
#          release_key('key.mouse.left')
#          press_key('key.mouse.left')
          @history_str < "."
          was = false
          break
        end
        block = r['block']
        #puts "[2] #{r['pos']}"
        @prev_block = block
        was = true
        step += 1
        sleep 0.1
        MC.invalidate_cache!
        r = MC.player['looking_at']
      end

      if was
        ore_name = ORE_NAMES[block['id']] || block['id'].sub("minecraft:","").sub(/_(ore|block)$/,'')
        #puts "new ore! (#{block['id']})" if @stats[ore_name] == 0
        @stats[ore_name] += 1
        if (color = get_color(ore_name))
          @history_str << ore_name[0].send(color)
        else
          @history_str << ore_name[0]
        end
      end

      break if player_acted?
      #break if dt >= BLOCK_MINE_TIMEOUT # rescan area after long time
      break if MC.player.inventory[36..39]&.map(&:skyblock_id).all?{ |x| x =~ /MINERAL/ }

      sleep rand()*0.1
    end
  end
end # mine_static!

if $0 == __FILE__
  begin
    while MC.current_map != "Your Island" && MC.current_map != "Hub"
      mine_static!
    end
  ensure
    release_key 'key.mouse.left'
  end
end
