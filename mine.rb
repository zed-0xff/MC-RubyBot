#!/usr/bin/env ruby
# frozen_string_literal: true
require 'json'
require 'uri'
require 'net/http'
require 'pp'
require 'open-uri'

ACTION_URI = URI('http://localhost:9999/action')

class Pos
  attr_accessor :x, :y, :z

  def initialize x, y=nil, z=nil
    if x.is_a?(Hash)
      h = x.transform_keys(&:to_sym)
      @x, @y, @z = h[:x], h[:y], h[:z]
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
end

@status_timestamp = nil
@status = nil

def status
  if @status.nil? || ((Time.now-@status_timestamp) > 5)
    @status_timestamp = Time.now
    data = nil
    data = URI.open("http://localhost:9999").read
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
      minX: pos.x-r, minY: pos.y-1, minZ: pos.z-r,
      maxX: pos.x+r, maxY: (pos.y+[3, r].min), maxZ: pos.z+r,
    }}
  ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
  data = res.body
  begin
    JSON.parse(data)
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
MAX_STEPS  = 20

def move_to target
  target = Pos.new(target) if target.is_a?(Hash) && target.key?("x")
  puts "[d] move_to #{target}"
  steps = 0
  prev_pos = status['player']['pos']
  while (pos.x.to_i != target.x.to_i || pos.z.to_i != target.z.to_i) && steps < MAX_STEPS
    delta = target-pos
    break if delta.x < MIN_TRAVEL && delta.z < MIN_TRAVEL
    travel delta
    sleep 0.05
    steps += 1
  end
  @status = nil
  prev_pos != status['player']['pos']
end

def look_at target
  target = Pos.new(target) if target.is_a?(Hash) && target.key?("x")
  script = [ { command: "lookAt", target: target.to_h, delay: (10+rand(20)) } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
  @status = nil
end

def mine!
  script = [ { command: "mine", delay: 250 } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
  @status = nil
end

@unreachables = Hash.new(0)
@unreach_player_pos = nil

def unreachable pos
  if @unreach_player_pos != status['player']['pos']
    puts "\n[d] clearing unreachables"
    @unreach_player_pos = status['player']['pos']
    @unreachables.clear
  end
  @unreachables[pos] += 1
  $stdout << "unreachable #{@unreachables[pos]}"
end

loop do
  ores = scan(4).
    find_all{ |x| x['id']['_ore'] }.
    sort_by{ |x| x['id']['_coal'] ? 0 : 1 }.
    delete_if{ |x| @unreachables[x['pos']] > 1 }

  if ores.empty?
    far_ores = scan(7).
      find_all{ |x| x['id']['_ore'] }.
      delete_if{ |x| @unreachables[x['pos']] > 1 }
    if far_ores.any?
      far_ores.shuffle.each do |ore|
        look_at ore['pos']
        break if move_to(ore['pos'])
        puts "[?] move failed"
        sleep 1
      end
    else
      sleep(1 + rand()*5)
    end
  else
    ores.each do |block|
      printf "[.] %s .. ", block.to_s

      #move_to Pos.new(block['pos'])
      look_at(Pos.new(block['pos']) + Pos.new(0.2+rand()/3, 0.2+rand()/3-1, 0.2+rand()/3))
      #look_at(Pos.new(block['pos']) + Pos.new(0, -1, 0))

      sleep 0.02
      if status.dig('player', 'looking_at', 'block').to_s['_ore']
        mine!
      else
        unreachable block['pos']
      end
      puts
      sleep rand()*0.2
    end
  end
end
