class Pos
  attr_accessor :x, :y, :z

  def initialize x, y=nil, z=nil
    case x
    when Hash
      h = x.transform_keys(&:to_sym)
      if h[:field_11175]
        raise "BUG!"
        @x, @y, @z = h[:field_11175], h[:field_11174], h[:field_11173]
      else
        @x, @y, @z = h[:x], h[:y], h[:z]
      end
    when Array
      @x, @y, @z = *x
    else
      @x, @y, @z = x, y, z
    end
  end

  def values
    [@x, @y, @z]
  end

  def to_i!
    @x = @x.to_i
    @y = @y.to_i
    @z = @z.to_i
    self
  end

  def eql? other
    if x.is_a?(Float) || other.x.is_a?(Float)
      x.round(2) == other.x.round(2) && y.round(2) == other.y.round(2) && z.round(2) == other.z.round(2)
    else
      x == other.x && y == other.y && z == other.z
    end
  end
  alias :== eql?

  def to_s
    inspect
  end

  def to_h
    { x: @x, y: @y, z: @z }
  end

  def to_a
    [@x, @y, @z]
  end

  def to_json(*args)
    to_h.to_json(*args)
  end

  def hash
    values.map(&:hash).sum
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
    def [] x, y=nil, z=nil
      x.is_a?(Pos) ? x : Pos.new(x, y, z)
    end
  end
end
