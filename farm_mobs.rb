#!/usr/bin/env ruby
require_relative 'autoattack'
require_relative 'enchant'
require 'set'

MAX_DISTANCE = 120
RADIUS_Y = 5

@blacklist = Set.new

def farm_mobs timeout: 1, range: 10..MAX_DISTANCE, radiusY: RADIUS_Y, filter: nil, enchant: true, classes: nil
  #puts "[d] farm_mobs timeout:#{timeout}, range:#{range}"
  attack_nearest(timeout: timeout, radiusY: 1, filter: filter)
  range.each do |d|
    respect_player delay: 0.1
    # wait for heal
    if MC.player.hp_percent < 50
      while MC.player.hp_percent < 90
        attack_nearest timeout: 5, filter: filter
      end
    end
    if MC.player.inventory.free_slots_count < 4 && enchant
      enchant_inventory!
#      stash! if MC.player.inventory.count(/^ENCHANTED_/) > 64
    end

    mobs = getMobs(classes: classes, radius: d, radiusY: radiusY)['entities'].
      delete_if { |mob| max_hp(mob) > 2_000_000 || @blacklist.include?(mob['uuid']) }.
      #delete_if { |mob| max_hp(mob) > 100_000 }. # XXX
      delete_if { |mob| mob['id'] == 'minecraft:bat' }. # XXX
      sort_by do |mob|
        if mob['id'] == 'minecraft:zealot' && max_hp(mob) == 2000
          # special zealot
          0
        else
          MOB_PRIORITIES[mob['id']] + (max_hp(mob) > 20000 ? 0 : 1) + distance(mob['boundingCenter'])/1000
        end
      end

    if filter
      mobs.delete_if{ |mob| !mob['name'][filter] }
    end

    if mobs.any?
      mob = mobs.first
      prio = MOB_PRIORITIES[mob['id']]
      mobs.each do |mob|
        printf "[d] %5.2f %s\n", distance(mob['pos']), shortstatus(mob) if mob['id'] =~ /enderman/
      end
      printf "[*] %d mobs within distance %d, moving to %s at %.1fm\n".yellowish,
        mobs.size, d, mob['id'].sub('minecraft:',''), distance(mob['pos'])
      extra_cmd = { command: "getEntityByUUID", stringArg: mob['uuid'] }
      speedup!
      MC.outline_entity! mob['uuid']
      success = ai_move_to(mob['pos']) do
        MC.look_at! mob['eyePos']
        r = getMobs(classes: classes, reachable: true, extra_commands: [extra_cmd])
        r['entities'].any? { |other_mob| MOB_PRIORITIES[other_mob['id']] <= prio } ||
          !r['entity'] || !r['entity']['alive']
      end
      if !success && (hp(mob) == max_hp(mob) || max_hp(mob) == 750_000) # XXX FIXME!
        return false
#        puts "[:] blacklisting #{shortstatus(mob)}".yellow
#        File.write "blacklisted_mob.json", mob.to_json
#        @blacklist << mob['uuid']
      end
      return true
    end
  end
  false
end

@next_warp = Time.now + 90

def warp!
  return false
  return false if Time.now < @next_warp

  dt = nil
  map = MC.current_map
  if map == "Private Island"
    MC.chat! "/warp end"
    sleep 3
    MC.set_pitch_yaw! yaw: 78
    MC.press_key! 'w'
    sleep 5
    MC.release_key! 'w'
    dt = 180
  else
    MC.chat! "/warp home"
    sleep 3
    dt = 60
  end

  if MC.current_map != map
    @next_warp = Time.now + dt
    true
  else
    false
  end
end

if $0 == __FILE__
  if ARGV.any?
    ARGV.cycle do |filter|
      if filter['|']
        filter = Regexp.new(filter)
      end
      farm_mobs(timeout: 0.2, range: 5..25, radiusY: 8, filter: filter)
      warp! || move_a_bit
    end
  else
    loop do
      farm_mobs(timeout: 0.2, range: 5..25, radiusY: 8)
      warp! || move_a_bit
    end
  end
end
