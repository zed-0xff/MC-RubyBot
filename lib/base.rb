class Base
  attr_accessor :data
  def initialize data
    @data = data
  end

  def short_id
    self.id.sub("minecraft:", "")
  end

  def dig *args
    @data.dig *args
  end

  def [] idx
    @data && @data[idx]
  end

  def inspect
    idata = @data.inspect
    if idata.size > 100
      "#<#{self.class}: #{@data.keys.inspect}>"
    else
      "#<#{self.class}: #{idata}>"
    end
  end

  def method_missing mname, *args
    if @data.key?(mname.to_s)
      @data[mname.to_s]
    else
      super
    end
  end

  def _colorize text, color
    return text if !color || text.empty?
    text.send(COLOR_ALIASES[color] || color)
  end

  def _decode_formatted_line line, color: false
    x = JSON.parse(line)
    if x['extra']
      if color
        x['extra'].map{ |x| _colorize(x['text'], x['color']) }.join(' ').strip
      else
        x['extra'].map{ |x| x['text'] }.join(' ').strip
      end
    else
      x['text'].strip
    end
  end

  def decode_formatted_text *path, color: false
    r = @data.dig(*path)
    return nil unless r
    if r.is_a?(String) && r[0] == "{"
      # single line
      _decode_formatted_line(r, color: color)
    elsif r.is_a?(Array)
      # multiline
      r.map { |line| _decode_formatted_line(line, color: color) }.join("\n")
    else
      raise "don't know how to decode: #{r.inspect}"
    end
  end
end

