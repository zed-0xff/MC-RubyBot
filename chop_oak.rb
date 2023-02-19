#!/usr/bin/env ruby
# frozen_string_literal: true
require 'json'
require 'uri'
require 'net/http'
require 'pp'
require 'open-uri'

ACTION_URI = URI('http://127.0.0.1:9999/action')

class Array
  def random
    self[rand(size)]
  end
end

class Pos
  attr_accessor :x, :y, :z

  def initialize x, y=nil, z=nil
    case x
    when Hash
      h = x.transform_keys(&:to_sym)
      @x, @y, @z = h[:x], h[:y], h[:z]
    when Array
      @x, @y, @z = *x
    else
      @x, @y, @z = x, y, z
    end
  end

  def to_s
    inspect
  end

  def to_h
    { x: @x, y: @y, z: @z }
  end

  def - other_pos
    Pos.new(
      x - other_pos.x,
      y - other_pos.y,
      z - other_pos.z
    )
  end

  def + other_pos
    Pos.new(
      x + other_pos.x,
      y + other_pos.y,
      z + other_pos.z
    )
  end

  class << self
    def [] x
      x.is_a?(Pos) ? x : Pos.new(x)
    end
  end
end

def distance a, b
  Math.sqrt((a.x-b.x)**2 + (a.z-b.z)**2)
end

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

def scan r=3
  script = [
    { command: "blocks", box: {
      minX: pos.x-r, minY: pos.y,              minZ: pos.z-r,
      maxX: pos.x+r, maxY: (pos.y+[4, r].min), maxZ: pos.z+r,
    }}
  ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
  data = res.body
  begin
    JSON.parse(data)['blocks']
  rescue JSON::ParserError
    puts data
    raise
  end
end

def travel target
#  target.y = 0
  puts "[d] travel #{target}"
  @status = nil
  script = [ { command: "travel", target: target.to_h } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
end

MIN_TRAVEL = 0.01
MAX_STEPS_PER_M  = 5

def press_key key, delay = 0
  script = [ { command: "key", stringArg: "key.keyboard.#{key}", delay: delay } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
end

def release_key key
  script = [ { command: "key", stringArg: "key.keyboard.#{key}", delay: -1 } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
end

def move_to target
  target = Pos[target]
  puts "[d] move_to #{target}"
  look_at target
  steps = 0
  prev_pos = status['player']['pos']
  prev_delta = distance(target, pos)
  max_steps = [prev_delta, 1].max*MAX_STEPS_PER_M
  t0 = Time.now
  press_key 'w'
  sleep 0.05
  while (pos.x.to_i != target.x.to_i || pos.z.to_i != target.z.to_i) && steps < max_steps
    steps += 1
    look_at target if steps%20 == 0
    @status = nil
    delta = distance(target, pos)
    printf "\r[d] step %3d (of max %d): delta=%5.3f  ", steps, max_steps, delta
    break if delta < MIN_TRAVEL || delta > prev_delta
    sleep 0.02
    prev_delta = delta
  end
  release_key 'w'
  puts
  t1 = Time.now
  puts "[d] held forward for #{(t1-t0).round(3)}s, made #{steps} steps, delta: #{delta}"
  @status = nil
  (prev_pos != status['player']['pos'])
rescue
  release_key 'w'
  raise
rescue Interrupt
  release_key 'w'
  exit
end

def look_at target
  target = Pos[target]
  script = [ { command: "lookAt", target: target.to_h, delay: (10+rand(20)) } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
  @status = nil
end

def chop!
  script = [ { command: "mine", delay: (650+rand(200)) } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
  @status = nil
end

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

def is_oak?(x)
  x == "minecraft:oak_wood" || x == "minecraft:oak_log"
end

def is_house? pos
  (-153..-136).include?(pos['x']) && (-40..-27).include?(pos['z'])
end

def find_far_oaks
  6.upto(10).each do |dist|
    far_oaks = scan(dist).
      find_all{ |x| is_oak?(x['id']) }.
      delete_if{ |x| @unreachables[x['pos']] > 1 }.
      delete_if{ |x| is_house?(x['pos']) }
    if far_oaks.any?
      puts "[d] #{far_oaks.count} oaks at distance #{dist}"
      far_oaks.shuffle.each do |ore|
        look_at ore['pos']
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
        sleep 1
      end
      break
    end
  end
  puts "[?] no far oaks"
  false
end

def in_bounds?
  (-200..-100).include?(pos.x) && (-70..17).include?(pos.z)
end

START_POSITIONS = [
  [-134.5, 73, -23],
  [-134.5, 73, -42],
  [-124,   74, -35.5],
  [-124,   74, -27.5],
]

loop do
  move_to START_POSITIONS.random unless in_bounds?

  oaks = scan(4).
    find_all{ |x| is_oak?(x['id']) }.
    delete_if{ |x| @unreachables[x['pos']] > 1 }.
    delete_if{ |x| is_house?(x['pos']) }

  puts "[d] #{oaks.count} oaks nearby"

  if oaks.empty?
    move_to START_POSITIONS.random unless find_far_oaks
  else
    oaks.shuffle[0,2].each do |block|
      printf "[.] %s .. ", block.to_s

      look_at(Pos.new(block['pos']) + Pos.new(0.2+rand()/3, 0.2+rand()/3-1, 0.2+rand()/3))

    #  sleep 0.02
      if is_oak?(status.dig('player', 'looking_at', 'block', 'id'))
        chop!
      else
        unreachable block['pos']
      end
      puts
    #  sleep rand()*0.2
    end
  end
end
