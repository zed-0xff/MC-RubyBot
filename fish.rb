#!/usr/bin/env ruby
require_relative 'autoattack'

# witch is too fast (
SHOOT_MOBS = %w'iron_golem guardian squid ocelot skeleton zombie zombie_horse wither silverfish snow_golem player'
SHOOT_RANGE = 14

@tStart = Time.now
@prevXp = MC.player.dig('skills', 'Fishing', 'currentXp')
@prevMax = MC.player.dig('skills', 'Fishing', 'currentXpMax')
@totalXp = 0

def next_level_msg xpm
  skill = MC.player.dig('skills', 'Fishing')
  min = (skill['currentXpMax'] - skill['currentXp']) / xpm
  eta, smiley =
    if min < 60
      [sprintf("%dm".greenish, min), ":]".greenish]
    elsif (h=min/60.0) < 4
      [sprintf("%4.1fh", h), ":)"]
    elsif (h=min/60.0) < 24
      [sprintf("%4.1fh", h), ":|"]
    else
      [sprintf("%4.1fh", h), ":("]
    end
  sprintf "%s until next level %s", eta, smiley
end

def check_exp
  if (currentXp = MC.player.dig('skills', 'Fishing', 'currentXp'))
    if @prevXp && currentXp != @prevXp
      currentMax = MC.player.dig('skills', 'Fishing', 'currentXpMax')
      if currentMax != @prevMax
        @prevXp = MC.player.dig('skills', 'Fishing', 'currentXp')
        @prevMax = currentMax
        @tStart = Time.now
        return
      end
      @lastXpTime = t = Time.now
      delta = currentXp - @prevXp
      @totalXp += delta
      msg = "%3d Fishing XP!".green % delta
      if @ntrophies > 0
        msg << " and %d trophies!".yellow % @ntrophies
      end
      xpm = @totalXp*60.0/(t-@tStart)
      #msg << " " << next_level_msg(xpm)
      printf "[*] %02d:%02d  %s\n", t.hour, t.min, msg
      #MC.set_overlay_message! ansi2mc(msg), tint: !!msg[":)"], ttl: 300
    end
    @prevXp = currentXp
  end
end

def look_at_water
  MC.set_pitch_yaw!(
    pitch: PITCH-0.5+rand(),
    yaw: YAW-0.5+rand(),
    delay: 20
  )
end

@ntrophies = 0
@prev_expertise = nil
@hook_pos = nil
@hook_ticks = 0

def break_ice! r = status
#  return unless status.dig('MC.player', 'looking_at', 'block', 'id') == "minecraft:ice"
#  puts "[.] breaking ice.."
#  press_key 'key.mouse.left', 2000
#  blocks = scan(radius: 3)['blocks'].
#    sort_by{ |block| distance(block['pos']) }
#
#  press_key 'key.mouse.left', 0
#  @left_mouse_pressed = true
#
#  blocks.each do |block|
#    if block['id'] == 'minecraft:ice'
#      look_at(Pos[block['pos']] + Pos[rand()/10-0.05, 0.8, rand()/10-0.05])
#      sleep 0.9
#    end
#  end
#
#  release_key 'key.mouse.left'
#  @left_mouse_pressed = false
end

def fish! look_at_water: true
  if MC.current_zone == "Jerry's Workshop"
    # break ice
    press_key 'key.mouse.left', 0
  end

  if (stack = MC.player.inventory.find{ |stack| stack.dig("tag", "ExtraAttributes", "id").to_s =~ /OBFUSCATED_FISH/ })
    puts "[*] got a trophy!".yellow
    @ntrophies += 1
    select_slot 0
    chat "/ec"
    if wait_for_screen(/Ender Chest/, raise: false)
      sleep 0.1
      slot = MC.screen.slots[54..88].find { |slot| slot.stack&.skyblock_id == stack.skyblock_id }
      if slot
        slot.quick_move!
        sleep 0.1
        MC.close_screen!
      else
#        MC.close_screen!
#        play_sound "entity.shulker.ambient"
#        say "§c§lrefusing to fish with a trophy in inventory!"
#        attack_nearest timeout: 10
      end
      #return
    end
  end
  if (rod = MC.player.inventory.find{ |stack| stack.dig("tag", "ExtraAttributes", "expertise_kills") })
    cur_expertise = rod.dig("tag", "ExtraAttributes", "expertise_kills")
    if cur_expertise != @prev_expertise
      if @prev_expertise
        printf "[*] +%d expertise!".green, cur_expertise-@prev_expertise
        puts " (total #{cur_expertise})"
      end
      @prev_expertise = cur_expertise
    end
  end
  look_at_water() if look_at_water && rand(60) == 1
  if (hook=MC.player.fishHook)
    if hook['pos'] == @hook_pos && MC.current_map != 'Crimson Isle'
      @hook_ticks += 1
      if @hook_ticks > 5
        puts "[?] fish hook is not moving. recasting..".yellowish
        move_a_bit(40)
        break_ice!
        select_slot 1
        @hook_ticks = 0
      end
    else
      @hook_pos = hook['pos']
      @hook_ticks = 0
    end
  else
    look_at_water() if look_at_water

    # TODO: dark/light bait

    select_tool /_ROD$/
    #right_click! 
    MC.interact_item!
    sleep 0.5
  end
end

START = MC.player.pos.dup
PITCH = MC.player.pitch
YAW   = MC.player.yaw

@last_zap = Time.now - 1000
prev_hp = MC.player.hp
#fish!

ZAP_TOOL = /INK_WAND/
ZAP_PROB = ARGV.first ? ARGV.first.to_f : 0.7

def zap_mobs!
  return false unless MC.player.has?(ZAP_TOOL)
  return false if Time.now - @last_zap < 30

  if rand() > ZAP_PROB
    @last_zap = Time.now
    return false
  end

  far_mobs = getMobs(radius: SHOOT_RANGE)['entities'].
    delete_if{ |mob| max_hp(mob) <= 20 }. # pets?
    delete_if{ |mob| mob['name'] =~ /Gravel Skeleton/ }.
    sort_by{ |mob| distance(mob['eyePos']) }

  far_mobs.each do |mob|
    printf "[m] %4.1f %4.1f %s\n",
      distance(mob['eyePos']), 
      mob['eyePos']['y'] - MC.player['eyePos']['y'],
      mob['id'].sub('minecraft:','')

    if SHOOT_MOBS.include?(mob['id'].sub('minecraft:',''))
      puts "[*] zap #{shortstatus(mob)}"
      MC.look_at! mob['eyePos']
      sleep 0.05
      with_tool(ZAP_TOOL) do
        MC.interact_item!
      end
      sleep 0.05
      @last_zap = Time.now
      break
    end
  end

  true
end

def shoot_mobs!
  zap_mobs!
end

if $0 == __FILE__
  loop do
    respect_player

    if MC.player['speed'] != 0
      sleep 0.1
      next
    end

    extra_commands = [{
      command: "blocksRelative", expand: {x: 4, y:4, z: 4}
    }]
    r = getMobs(reachable: :loose, extra_commands: extra_commands)
    overlay = r.dig('overlay')
    #puts "[d] #{overlay}" if overlay.to_s['Fishing']
    blocks = r['blocks']
    mobs = r['entities'].
      delete_if{ |mob| max_hp(mob) <= 20 }. # pets?
      delete_if{ |mob| mob['id'] == 'minecraft:wither' && max_hp(mob) == 300 } # pets?

    new_mobs = mobs.find_all{ |mob| !mob['outlineColor'] }
    if new_mobs.any?
      MC.script do
        new_mobs.each do |mob|
          puts "[.] marking #{shortstatus(mob)}".red
          outline_entity! mob['uuid']
        end
      end
      #    # stand by (do not fish!) while mobs are close
      #    sleep 1
      #    next
    end

    if mobs.any? || MC.player.hp < prev_hp #{ |mob| hp(mob) != max_hp(mob) }
      select_slot 0
      attack_nearest timeout: (1.8 + rand()/5)
    else
      shoot_mobs!
    end

    mobs = getMobs(radius: 5)['entities']
    next if mobs.any?
    if distance(START) > 2 && MC.has_mod?('baritone')
      release_key 'key.mouse.left'
      ai_move_to(START) do
        mobs = getMobs(radius: 5)['entities']
        mobs.any?
      end
    end
    next if mobs.any?

    if blocks.any?{ |b| b['id'] == 'minecraft:water' } || MC.current_map == 'Crimson Isle' || MC.current_map == "Spider's Den"
      fish!
    else
      puts "[?] no water around"
      sleep 1
    end
    sleep 0.5
    check_exp
    #move_a_bit
    prev_hp = MC.player.hp
  end
end
