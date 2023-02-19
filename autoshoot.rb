#!/usr/bin/env ruby
require_relative 'lib/common'

MOB_PRIORITIES = Hash.new(100) # default
MOB_PRIORITIES["minecraft:enderman"] = 10
MOB_PRIORITIES["minecraft:endermite"] = 1000

def max_hp mob
  mob.dig('nbt', 'Attributes').find{ |a| a['Name'] == 'minecraft:generic.max_health' }['Base']
rescue
  0
end

def hp mob
  mob.dig('nbt', 'Health').to_f
end

@mobs_hp = {}

def shortstatus mob
  a = []
  a << "[%s]: %-10s" % [mob['uuid'][-6..-1], mob['id'].sub('minecraft:','')]

  hp_ratio = hp(mob) / max_hp(mob)
  hp_info = "%6d/%-6d" % [hp(mob), max_hp(mob)]
  if hp_ratio > 0.5
    a << hp_info.greenish
  elsif hp_ratio > 0.1
    a << hp_info.yellowish
  else
    a << hp_info.red
  end

  hp = hp(mob).to_i
  uuid = mob['uuid']
  if (prev_hp=@mobs_hp[uuid])
    hp_delta = hp-prev_hp
    if hp_delta != 0
      a << hp_delta.to_s
    end
  end
  @mobs_hp[uuid] = hp

#  a << "dist=%.2f e2e=%.2f e2b=%.2f" % [
#    distance(mob['boundingCenter']),
#    distance(player['eyePos'], mob['eyePos']),
#    distance(player['eyePos'], mob['boundingCenter']),
#  ]
  a.join(' ')
end

def shoot! mob
  mob_pos = Pos[mob['pos']]
  key = 
    if hp(mob) > 20_000
      "eyePos"
    elsif mob_pos.y > player.pos.y
      "boundingCenter"
    elsif mob_pos.y < player.pos.y
      "eyePos"
    else
      (rand(10) > 7) ? "boundingCenter" : "eyePos"
    end
  d = distance(mob_pos)
  pos = Pos[mob[key]] + Pos.new(0.2-rand()/10, ((d > 10 ? 0.8 : 0.2)-rand()/10), 0.2-rand()/10)
  look_at(pos)
  right_click!
  sleep 0.4 + rand/10
  right_click!
  sleep 0.4 + rand/10
end

def save_mob mob
  return unless mob
  File.write(File.join("mobs", mob['id'].sub('minecraft:','') + ".json"), mob.to_json)
end

def attack_nearest timeout: 0
  MC.cache_ttl = [0.05, MC.cache_ttl].min

  @attacking_uuid = nil
  @was = true

  t0 = Time.now
  prevmsg = nil
  loop do
    #autoheal
    respect_player delay: 0.1
    r = getMobs(radius: 20)
    mobs = r['entities'].
      delete_if { |mob| max_hp(mob) > 2_000_000 }.
      sort_by { |mob| MOB_PRIORITIES[mob['id']]*100 + distance(mob['boundingCenter']) }
    if mobs.any?
      @status = nil
      t0 = Time.now
      looking_at_uuid = r.dig('looking_at', 'entity', 'uuid')
      @was = true
      mobs.shuffle[0,2].each do |mob|
        mpos = Pos[mob['boundingCenter']]
        msg = shortstatus(mob)
        puts "[.] #{msg}" if !prevmsg.to_s.start_with?(msg)
        shoot! mob
        prevmsg = msg
      end
      mob = nil

    else
      puts("[.] waiting for mobs ..") if @was
      @was = false
      if timeout > 0
        if (dt = Time.now-t0) > timeout
          printf "[*] no mobs for %.1fs, exiting loop\n", dt
          return
        end
      end
    end
    #sleep(0.1 + rand()/10)
    move_a_bit 30
  end
end

if $0 == __FILE__
  attack_nearest
end
