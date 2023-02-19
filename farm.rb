#!/usr/bin/env ruby
require_relative 'lib/common'
require_relative 'enchant'

TREE_TYPES = ARGV
raise "gimme tree type" if TREE_TYPES.empty?

auto_jump true

MC.cache_ttl = 0.1
CONFIG = YAML::load_file 'crops.yml'

#def scan r=3
#  script = [
#    { command: "blocks", box: {
#      minX: pos.x-r, minY: pos.y-[3, r].min,   minZ: pos.z-r,
#      maxX: pos.x+r, maxY: (pos.y+[4, r].min), maxZ: pos.z+r,
#    }}
#  ]
#  res = Net::HTTP.post(ACTION_URI, script.to_json)
#  data = res.body
#  begin
#    JSON.parse(data)['blocks']
#  rescue JSON::ParserError
#    puts data
#    raise
#  end
#end

def scan radius: BLOCK_REACHABLE_DISTANCE, radiusY: BLOCK_REACHABLE_DISTANCE
  script = [
    { command: "blocksRelative",
      expand: { x: radius, y: 0.5, z: radius },
#      offset: { x: 0, y: 1.5, z: 0 },
    }
  ]
  JSON.parse(Net::HTTP.post(ACTION_URI, script.to_json).body)['blocks']
end

def travel target
#  target.y = 0
  puts "[d] travel #{target}"
  MC.invalidate_cache!
  script = [ { command: "travel", target: target.to_h } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
end

MIN_TRAVEL = 0.01
MAX_STEPS_PER_M = 10

# prevent looping between last points
SAVE_LAST_MOVES = 5
@last_moves = []


def move_to target
  target = Pos[target]
  prev_dist = distance(target)
  puts "[d] move_to #{target}, dist=#{prev_dist}"
  #return ai_move_to(target) #if prev_dist > 20
  return ai_move_to(target) do
    l = look_at target
    if l['block'] && is_crop?(l['block']['id'])
      sleep 0.2
      true
    else
      false
    end
  end



  @last_moves << target.dup
  @last_moves.last.y = 0
  @last_moves.uniq!
  @last_moves.shift if @last_moves.size > SAVE_LAST_MOVES
  look_at target
  steps = 0
  prev_pos = status['player']['eyePos']
  max_steps = [prev_dist, 1].max*MAX_STEPS_PER_M
  tree_seen = false
  impassable = false
  t0 = Time.now
  press_key 'w'
  sleep 0.02
  while distance(target) > 2 && steps < max_steps
    steps += 1
    l = look_at(target)
    if l['block'] && !l['block']['canPathfindThrough'] && l['distanceXZ'] < 1.0
#      $stdout << "[!] impassable: #{l}".red
      impassable = true
    end
    MC.invalidate_cache!
    dist = distance(target)
    printf "\r[d] step %3d (of max %d): dist=%5.3f  ", steps, max_steps, dist
    if is_crop?(id=status.dig('player', 'looking_at', 'block', 'id'))
      $stdout << id.greenish
      tree_seen = true
      break
    end
    if dist < MIN_TRAVEL
      $stdout << "dist < MIN_TRAVEL".yellowish
      break
    end
    if dist > prev_dist
      $stdout << "dist > prev_dist".yellowish
      break
    end
    sleep 0.02
    prev_dist = dist
  end
  release_key 'w'
  puts
  t1 = Time.now
  puts "[d] held forward for #{(t1-t0).round(3)}s, made #{steps} steps, dist: #{dist}"
  MC.invalidate_cache!
  r = (prev_pos != status['player']['pos']) || tree_seen
  return r if r
  return ai_move_to(target) # if impassable
rescue
  release_key 'w'
  raise
rescue Interrupt
  release_key 'w'
  exit
end

#def chop!
#  script = [ { command: "mine", delay: (650+rand(200)) } ]
#  res = Net::HTTP.post(ACTION_URI, script.to_json)
#  MC.invalidate_cache!
#end

@unreachables = Hash.new(0)
@unreach_player_pos = nil

def unreachable pos
  if @unreach_player_pos != status['player']['pos']
    @unreach_player_pos = status['player']['pos']
    @unreachables.clear
  end
  @unreachables[pos] += 1
  $stdout << "unreachable #{@unreachables[pos]} (dist #{distance(pos, status['player']['pos']).round(3)})"
end

def is_crop?(x)
  TREE_TYPES.any? { |t| x.to_s[t] }
end

def is_house? pos
#  (-153..-136).include?(pos['x']) && (-40..-27).include?(pos['z'])
  (-358..-350).include?(pos['x']) && (-25..-21).include?(pos['z'])
end

START_POSITION = pos
START_POSITIONS = [ pos ]
MAX_DISTANCE = 22
MIN_DISTANCE = BLOCK_REACHABLE_DISTANCE*1.5

def move_randomly n = 1
  n.times do
    case rand(6)
    when 0
      press_key 'w', 50+rand(500)
    when 1
      press_key 'a', 50+rand(500)
    when 2
      press_key 's', 50+rand(500)
    when 3
      press_key 'd', 50+rand(500)
    when 4
      press_key 'space', 50+rand(250)
    end
  end
end

def _find_far_crops min_dist, max_dist
  min_dist.to_i.upto(max_dist.to_i).each do |dist|
    far_crops = scan(radius: dist).
      find_all{ |x| is_crop?(x['id']) }.
      delete_if{ |x| @unreachables[x['pos']] > 1 }.
      delete_if{ |x| blacklisted?(x) }.
      delete_if{ |x| is_house?(x['pos']) }.
      delete_if{ |x| distance(pos, x['pos']) < MIN_DISTANCE }.
      delete_if{ |x| @last_moves.any?{ |l| x['pos']['x'] == l.x && x['pos']['z'] == l.z } }
    if far_crops.any?
      puts "[d] #{far_crops.count} crops at distance #{dist}"
      far_crops.shuffle.each do |crop|
        look_at crop['pos']
        return true if move_to(crop['pos'])
        puts "[?] move failed"
        move_randomly 1 + rand(2)
        puts "[d] sleep .."
        sleep 0.3
      end
      break
    end
  end
  puts "[?] no far crops at #{min_dist.to_i}..#{max_dist.to_i}".yellowish
  false
end

def find_far_crops
  _find_far_crops(BLOCK_REACHABLE_DISTANCE*1.2, 20) ||
    _find_far_crops(BLOCK_REACHABLE_DISTANCE*0.9, BLOCK_REACHABLE_DISTANCE*1.5) ||
    _find_far_crops(20, 60) ||
    _find_far_crops(60, 100)
end

def return_home
  new_pos = START_POSITIONS.random
  new_pos.x += (rand(4)-2)
  new_pos.z += (rand(4)-2)
  move_to new_pos
end

def reachable? xpos
  @unreachables[xpos] < 2 && distance(xpos, pos) < BLOCK_REACHABLE_DISTANCE
end

def blacklisted? x
  xpos = x['pos']
  CONFIG['blacklist'].include?({'x' => xpos['x'], 'z' => xpos['z'] }) ||
    x['id']['potted_cactus']
end

def in_bounds?
  #distance(pos, START_POSITION) < MAX_DISTANCE
  true
end

def current_tool
  slot_id = status.dig('player', 'hotbar', 'selectedSlot')
  status.dig('player', 'nbt', 'Inventory').find{ |x| x['Slot'] == slot_id }
end

def is_slow_crop? x
  case x
  when /cactus/
    (current_tool.dig("tag", "ExtraAttributes", "id") != "CACTUS_KNIFE") && 0.8
  when /cocoa/
    0.5
  when /dark_oak/
    0.5
  else
    false
  end
end

START = Pos[pos]

loop do
  return_home unless in_bounds?

  while player.inventory.full?
    begin
      enchant_all!
    rescue => e
      puts "[!] #{e}".red
      sleep 5
    end
  end

  crops = scan(radius: 4).
    find_all{ |x| is_crop?(x['id']) }.
    delete_if{ |x| !reachable?(x['pos']) }.
    delete_if{ |x| blacklisted?(x) }.
    delete_if{ |x| is_house?(x['pos']) }

  $stdout << "\r[.] %d crops nearby " % crops.count

  byxz = Hash.new{ |k,v| k[v] = [] }
  crops.each do |c|
    byxz[[c['pos']['x'], c['pos']['z']]] << c
  end
  byxz.each do |k,a|
    if a.size > 1
      root = a.sort_by { |c| c['pos']['y'] }.first
      root['length'] = a.size
      a -= [root]
      crops -= a
    end
  end

  crops.sort_by{ |c| distance(c['pos']) }.each do |block|
    $stdout << "\r[.] %d crops nearby: %s  " % [crops.count, block.to_s]
    1.times do
      r = look_at(Pos.new(block['pos']) + Pos.new(0.4+rand()/5, 0.4 + rand()/10 , 0.4+rand()/5), delay: 40+rand(10))
      if (delay=is_slow_crop?(r.dig('block', 'id')))
        sleep(delay + rand()/5)
        break
      end
    end
  end
  puts

  find_far_crops || ai_move_to(START)
end
