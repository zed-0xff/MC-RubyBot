# frozen_string_literal: false

class Map
  attr_reader :rx, :rz

  def initialize
    @data = Hash.new{ |k,v| k[v] = {} }
    @rx = nil
    @rz = nil
  end

  # not only a block, any object that has coords and id
  def put block, value = nil
    x = block['pos']['x']
    x = x.round if x.is_a?(Float)
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
    z = z.round if z.is_a?(Float)
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

    @data[z][x] = (value || block['id'].sub('minecraft:','')[0].upcase)
  end

  def to_s
    s = ''
    i = 0
    @rz.each do |z|
      s << sprintf("%x ", i&0x0f)
      i += 1

      @rx.each do |x|
        s << (@data[z][x] || " ").to_s
      end
      s << "\n"
    end
    s
  end

  def [] z
    @data[z]
  end
end

