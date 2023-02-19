#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'enchant'

auto_jump true
MC.cache_ttl = 0.1

TREE_TYPES = ARGV
raise "gimme tree type" if TREE_TYPES.empty?

@status_timestamp = nil
@status = nil

def status
  if @status.nil? || ((Time.now-@status_timestamp) > 5)
    @status_timestamp = Time.now
    data = nil
    data = URI.open("http://127.0.0.1:9999").read
    begin
      @status = JSON.parse(data)
    rescue JSON::ParserError
      puts data
      raise
    end
  else
    @status
  end
end

def pos
  Pos.new status['player']['pos']
end

MIN_TRAVEL = 0.01
MAX_STEPS_PER_M = 2

#def press_key key, delay = 0
#  script = [ { command: "key", stringArg: "key.keyboard.#{key}", delay: delay } ]
#  res = Net::HTTP.post(ACTION_URI, script.to_json)
#end
#
#def release_key key
#  script = [ { command: "key", stringArg: "key.keyboard.#{key}", delay: -1 } ]
#  res = Net::HTTP.post(ACTION_URI, script.to_json)
#end

def move_to target
  speedup!
  #return ai_move_to(target) { is_tree?(MC.player.dig('looking_at', 'block', 'id')) }

  target = Pos[target]
  puts "[d] move_to #{target}"
  look_at target
  steps = 0
  prev_pos = status['player']['pos']
  prev_delta = distance(target, pos)
  max_steps = [prev_delta, 1].max*MAX_STEPS_PER_M
  tree_seen = false
  t0 = Time.now
  press_key 'w'
  sleep 0.05
  while (pos.x.to_i != target.x.to_i || pos.z.to_i != target.z.to_i) && steps < max_steps
    steps += 1
    look_at target # if steps%20 == 0
    @status = nil
    delta = distance(target, pos)
    printf "\r[d] step %3d (of max %d): delta=%5.3f  ", steps, max_steps, delta
    if is_tree?(id=status.dig('player', 'looking_at', 'block', 'id'))
      $stdout << id
      tree_seen = true
      break
    end
    break if delta < MIN_TRAVEL || delta > prev_delta
    sleep 0.02
    prev_delta = delta
  end
  release_key 'w'
  puts
  t1 = Time.now
  puts "[d] held forward for #{(t1-t0).round(3)}s, made #{steps} steps, delta: #{delta}"
  @status = nil
  (prev_pos != status['player']['pos']) || tree_seen
rescue
  release_key 'w'
  raise
rescue Interrupt
  release_key 'w'
  exit
end

def chop!
  sleep 0.8 # jungle axe  + Efficiency I + Haste II
#  sleep 0.5 # diamond axe + Efficiency V + Haste II
#  script = [ { command: "mine", delay: (650+rand(200)) } ]
#  res = Net::HTTP.post(ACTION_URI, script.to_json)
end

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

def is_tree?(x)
  x && TREE_TYPES.include?( x.sub("minecraft:", ""))
end

def is_house? pos
#  (-153..-136).include?(pos['x']) && (-40..-27).include?(pos['z'])
  (-381..-379).include?(pos['x']) && (-24..-16).include?(pos['z'])
  false
end

def find_far_trees
  6.upto(20).each do |dist|
    far_trees = scan(radius: dist, radiusY: 1)['blocks'].
      find_all{ |x| is_tree?(x['id']) }.
      delete_if{ |x| @unreachables[x['pos']] > 1 }.
      delete_if{ |x| is_house?(x['pos']) }
    if far_trees.any?
      puts "[d] #{far_trees.count} trees at distance #{dist}"
      far_trees.shuffle.each do |ore|
        pos = Pos.new(ore['pos'])
        pos.y = player.eyePos['y']
        look_at pos
        return true if move_to(ore['pos'])
        puts "[?] move failed"
        case rand(5)
        when 0
          press_key 'a', 50+rand(500)
        when 1
          press_key 's', 50+rand(500)
        when 2
          press_key 'd', 50+rand(500)
        when 3
          press_key 'space', 50+rand(250)
        end
        #puts "[d] sleep .."
        #sleep 1
      end
      break
    end
  end
  puts "[?] no far trees"
  false
end

START_POSITION = pos
START_POSITIONS = [ pos ]
MAX_DISTANCE = 22

def return_home
  new_pos = START_POSITIONS.random
  new_pos.x += (rand(4)-2)
  new_pos.z += (rand(4)-2)
  move_to new_pos
end

def reachable? xpos
  @unreachables[xpos] < 2 && distance(xpos, player.eyePos) < BLOCK_REACHABLE_DISTANCE
end

def in_bounds?
  distance(pos, START_POSITION) < MAX_DISTANCE
end


loop do
  respect_player

  if player.inventory.full?
    #release_key('key.mouse.left')
    begin
      enchant_inventory!
      #enchant_all! filter: 'MINING'
    rescue => e
      puts "[!] #{e}".red
      sleep 1
      return
    ensure
      MC.close_screen!
    end
  end

  return_home unless in_bounds?
  #press_key('key.mouse.left') if status['input']['key.mouse.left']['state'] == 0

  trees = scan(radius: 4, radiusY: 1)['blocks'].
    find_all{ |x| is_tree?(x['id']) }.
    delete_if{ |x| !reachable?(x['pos']) }.
    delete_if{ |x| is_house?(x['pos']) }

  puts "[d] #{trees.count} trees nearby"

  if trees.empty?
    return_home unless find_far_trees
  else
    # XXX for treecapitator!!!
    #trees.shuffle[0,2].each do |block|
    trees.
      sort_by{ |block| distance(player.eyePos, block['pos']) }[0,2].
      each do |block|
        printf "[.] %s .. ", block.to_s

        l = look_at(Pos.new(block['pos']) + Pos.new(0.2+rand()/3, 0.2+rand()/3, 0.2+rand()/3))
        # sleep 0.05

        if is_tree?(l.dig('block', 'id'))
          chop!
        else
          unreachable block['pos']
        end
        sleep 0.4
        puts
        #  sleep rand()*0.2
      end
  end
end
