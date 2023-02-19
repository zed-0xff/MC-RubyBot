# frozen_string_literal: true

class ToolAttributeTracker

  SLOTS = (0..7).to_a + (36..39).to_a

  def initialize
    @data = {}
  end

  def _parse_tool_attrs tool
    return nil unless tool
    lore = tool.lore
    return nil unless lore
    Hash[*lore.split("\n\n")[0].scan(/^([a-zA-Z ]+):\s+\+([^\s]+)/).flatten]
  end

  def track! status
    return unless (inv = status.dig('player', 'inventory'))
    r = []
    SLOTS.each do |slot|
      tool = inv[slot]
      tool = ItemStack.new(tool) if tool.is_a?(Hash)
      next unless (attrs = _parse_tool_attrs(tool))
      next unless (uuid = tool.uuid)

      if (prev_attrs = @data[uuid])
        attrs.each do |k,v|
          if v != prev_attrs[k]
            r << "#{tool.display_name}: #{k} #{prev_attrs[k]} -> #{v}".green
          end
        end
      end
      @data[uuid] = attrs
    end
    r
  end
end

if $0 == __FILE__
  require_relative 'common'
  tracker = ToolAttributeTracker.new
  loop do
    tracker.track! MC.status
    sleep 1
    MC.invalidate_cache!
  end
end
