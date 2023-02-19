# frozen_string_literal: true

class ToolCounterTracker
  SLOTS = (0..7).to_a + (36..39).to_a

  def initialize
    @tools = {}
  end

  def track! status
    return unless (inv = status.dig('player', 'inventory'))
    r = []
    SLOTS.each do |slot|
      tool = inv[slot]
      next unless (attrs = tool.dig('tag', 'ExtraAttributes'))
      next unless (uuid = attrs['uuid'])

      prev_tool = @tools[uuid] || tool
      prev_attrs = prev_tool.dig('tag', 'ExtraAttributes')
      attrs.each do |k,v|
        next unless v.is_a?(Integer)
        next if k['jyrre']
        next if k == 'compact_blocks'
        
        if prev_attrs[k] && v > prev_attrs[k]
          r << "#{k}: #{v}"
        end
      end
      @tools[uuid] = tool
    end
    r
  end
end
