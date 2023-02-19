#!/usr/bin/env ruby
require_relative 'lib/common'

class Map
  def initialize
    @data = Hash.new{ |k,v| k[v] = {} }
    @rx = nil
    @rz = nil
  end

  def put block
    x = block['pos']['x']
    @rx =
      if @rx
        if x < @rx.begin
          x..@rx.end
        elsif x > @rx.end
          @rx.begin..x
        else
          @rx
        end
      else
        x..x
      end

    z = block['pos']['z']
    @rz =
      if @rz
        if z < @rz.begin
          z..@rz.end
        elsif z > @rz.end
          @rz.begin..z
        else
          @rz
        end
      else
        z..z
      end

    @data[x][z] = block['id']
  end

  def to_s
    s = ''
    @rz.each do |z|
      @rx.each do |x|
        s << (@data[x][z] ? "XX" : "  ")
      end
      s << "\n"
    end
    s
  end
end

map = Map.new
r = scan(radius: 10, radiusY: 0, offset: { x:0, y: -1, z:0 })
blocks = r['blocks']
blocks.each do |block|
  map.put block
end

puts map.to_s

rx = Range.new(*blocks.map{ |b| b['pos']['x'] }.minmax)
rz = Range.new(*blocks.map{ |b| b['pos']['z'] }.minmax)
