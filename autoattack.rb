#!/usr/bin/env ruby
require_relative 'lib/common'

MOB_PRIORITIES = Hash.new(100) # default
MOB_PRIORITIES["minecraft:villager"] = 1 # Jerry
MOB_PRIORITIES["minecraft:player"] = 5
MOB_PRIORITIES["minecraft:witch"] = 5
MOB_PRIORITIES["minecraft:enderman"] = 10
MOB_PRIORITIES["minecraft:endermite"] = 1000
MOB_PRIORITIES["minecraft:silverfish"] = 1100

$mobs = {}

def shortstatus mob, dps: true
  uuid = mob['uuid']
  a = []
  a << "[%s]: %-10s" % [uuid[-6..-1], mob['id'].sub('minecraft:','')]

  prev_hp = hp($mobs[uuid])
  hp = hp(mob).to_i
  max_hp = max_hp(mob).to_i

  # keep it
  mob[:first_seen] = $mobs.dig(uuid, :first_seen) || Time.now
  mob[:start_hp]   = $mobs.dig(uuid, :start_hp)   || hp       # not necessary equal to max_hp

  $mobs[uuid] = mob

  hp_ratio = 1.0 * hp / max_hp
  hp_info = "%6d/%-6d" % [hp, max_hp]
  if hp_ratio > 0.5
    a << hp_info.greenish
  elsif hp_ratio > 0.1
    a << hp_info.yellowish
  else
    a << hp_info.red
  end

  if prev_hp
    # already seen
    if (hp_delta = hp-prev_hp) != 0
      a << format_number(hp_delta).rjust(5)
    else
      a << "".rjust(5)
    end
    if hp != mob[:start_hp] && dps
      dps = (mob[:start_hp] - hp) / (Time.now - mob[:first_seen])
      a << " #{format_number(dps)} DPS"
    end
  else
    # new mob
    a << mob['name']
  end

#  a << "dist=%.2f e2e=%.2f e2b=%.2f" % [
#    distance(mob['boundingCenter']),
#    distance(player['eyePos'], mob['eyePos']),
#    distance(player['eyePos'], mob['boundingCenter']),
#  ]
  a.join(' ')
end

def look_at_mob mob
  mob_pos = Pos[mob['pos']]
  pos = 
    if mob_pos.y > MC.player.pos.y
      Pos[mob["boundingCenter"]]
    elsif mob_pos.y < MC.player.pos.y
      Pos[mob["eyePos"]]
    else
      bc = Pos[mob["boundingCenter"]]
      dh = Pos[mob["eyePos"]].y - bc.y
      bc.y += dh*0.6
      bc
    end

  rand_pos = Pos.new(0.2-rand()/10, (0.2-rand()/10), 0.2-rand()/10)
  MC.script do
    outline_entity!(mob['uuid'])
    look_at!(pos + rand_pos)
  end
end

def save_mob mob
  return # disabled for now, need to strip special chars from names
  return unless mob
  fname =
    if mob['name']
      File.join("mobs", mob['name']) + ".json"
    else
      File.join("mobs", mob['id'].sub('minecraft:','')) + ".json"
    end
  File.write(fname, mob.to_json)
end

def attack_nearest timeout: 0, quiet: false, radiusY: nil, filter: nil
  #MC.cache_ttl = [0.05, MC.cache_ttl].min

  $attacking_uuid = nil
  $was = true

  t0 = Time.now
  prevmsg = nil
  loop do
    #autoheal
    move_a_bit 10
    respect_player delay: 0.1
    r = getMobs(reachable: :loose, radiusY: radiusY)

    mobs = r['entities'].
      delete_if { |mob| max_hp(mob) > 3_000_000 }.
      find_all { |mob| is_mob?(mob) }.
      sort_by { |mob| MOB_PRIORITIES[mob['id']]*100 + distance(mob['boundingCenter']) }

    if filter
      mobs.delete_if{ |mob| !mob['name'][filter] }
    end

    if mobs.any?
      $status = nil
      t0 = Time.now
      looking_at_uuid = r.dig('looking_at', 'entity', 'uuid')
      $was = true
      mobs.each do |mob|
        mpos = Pos[mob['boundingCenter']]
        msg = shortstatus(mob)
        puts "[.] #{msg}" if !prevmsg.to_s.start_with?(msg)
        prevmsg = msg
      end
      mob = nil

      siamese_cats = mobs.find_all { |mob| mob['id'] == 'minecraft:cat' && max_hp(mob) >= 30_000 }
      if siamese_cats.size > 1
        uuids = siamese_cats.map { |mob| mob['uuid'] }.sort
        $current_cat_index = 1 - $current_cat_index.to_i
        $attacking_uuid = uuids[$current_cat_index]
      end

      if $attacking_uuid
        mob = mobs.find{ |m| m['uuid'] == $attacking_uuid }
        if mob && looking_at_uuid != $attacking_uuid
          look_at_mob mob
        end
      end
      unless mob
        if looking_at_uuid
          mob = mobs.find{ |m| m['uuid'] == looking_at_uuid }
          $attacking_uuid = looking_at_uuid
          puts "[*] already attacking #{shortstatus(mob)}" if mob
          save_mob(mob)
          sleep(0.1 + rand()/10)
          next
        end
        mobs.each do |mob|
          next if mob['pos']['y'] > MC.player['eyePos']['y']
          $attacking_uuid = mob['uuid']
#          puts "[*] attacking #{shortstatus(mob)} ..".yellowish
          l = look_at_mob mob
          if l['block'] && !l['block']['canPathfindThrough']
            puts("[!] wall".red) unless quiet
            next
          end
          save_mob(mob)
          break
        end
      end
    else
      puts("[.] waiting for mobs ..") if $was && !quiet
      $was = false
      if timeout > 0
        if (dt = Time.now-t0) > timeout
          printf("[*] no mobs for %.1fs, exiting loop\n", dt) unless quiet
          return
        end
      end
    end

    # do not action too often!
    sleep(0.1 + rand()/5)
  end
end

if $0 == __FILE__
  attack_nearest
end
