#!/usr/bin/env ruby
require_relative 'lib/common'

def predict cur, prev
  cur = Pos[cur]
  prev = Pos[prev]
  if cur.x == prev.x
    cur.z += (cur.z - prev.z)
  elsif cur.z == prev.z
    cur.x += (cur.x - prev.x)
  end
  cur
end

def solve_control
  mob = MC.
    get_entities!(radius: 20)['entities'].
    find_all{ |m| m['id'] == 'minecraft:wither_skeleton' }.
    sort_by{ |m| m['network_id'] }.
    first
  unless mob
    sleep 0.1
    return
  end
  cur = mob['eyePos']
  if cur == @prev
    sleep 0.01
    return
  end
  MC.look_at!( predict(cur, @prev), delay: 0 )
  @prev = mob['eyePos']
end

def solve_force
  mob = @status.dig('player', 'looking_at', 'entity')
  return unless mob
  if mob['name'] =~ /^\d+/
    MC.attack_entity! uuid: mob['uuid']
  end
end

def solve_discipline
  mob = @status.dig('player', 'looking_at', 'entity')
  return unless mob
  re = Regexp.new(mob['name'].upcase)
  select_tool re
  MC.attack_entity! uuid: mob['uuid']
end

def _sort_key e
  r = e['name'].tr(':', '.').to_f
  cname = e.dig('nbt', 'CustomName')
  case cname
  when /red/
    r += 1000 #if r < 0.25
  when /yellow/
    r += 100 if r > 0.3
  when /green/
    r += 200
  end
  #printf "[d] %.3f %s\n", r, cname
  r
end

def solve_mastery
  MC.press_key! 'key.mouse.right'
  sleep 1.6
  loop do
    entities = MC.
      get_entities!( radius: 20, type: "ArmorStandEntity" )['entities'].
      find_all{ |e| e['id'] == 'minecraft:armor_stand' }.
      find_all{ |e| e['name'] =~ /^\d:\d/ }.
      sort_by{ |e| _sort_key(e) }
    e = entities.first
    if e && _sort_key(e) < 1
      printf "[d] %s %.3f\n", e['name'], _sort_key(e)
      MC.look_at!(Pos[e['pos']] + Pos.new(0, 4, 0))
      sleep 0.05
      MC.release_key! 'key.mouse.right'
      sleep 0.1
      break
    else
      sleep 0.05
    end
  end
end

loop do
  @status = MC.status!
  case @status.dig('sidebar', 7)
  when 'Challenge: Control'
    solve_control
  when 'Challenge: Force'
    solve_force
  when 'Challenge: Discipline'
    solve_discipline
  when 'Challenge: Mastery'
    solve_mastery
  end
end
