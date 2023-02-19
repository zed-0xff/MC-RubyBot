require_relative 'base'

class ItemStack < Base
  def inspect
    "#<#{self.class}: #{@data['Count'].to_s.rjust(2)} #{skyblock_id || id}>"
  end

  def count
    @data['Count']
  end
  alias :size :count

  def max_count
    @data['maxCount']
  end
  alias :max_size :max_count

  def slot_id
    @data['Slot']
  end

  def empty?
    !@data ||
      @data['id'] == 'minecraft:air' || 
      (
        @data['id'] =~ /_glass(_pane)?$/ &&
        @data['Count'] == 1 &&
        display_name.empty?
      )
  end

  def is_a? type
    item_matcher(type).call(self)
  end

  def skyblock_id
    @data.dig("tag", "ExtraAttributes", "id")
  end

  def uuid
    @data.dig("tag", "ExtraAttributes", "uuid")
  end

  def display_name color: false
    decode_formatted_text("tag", "display", "Name", color: color)
  end

  def lore
    decode_formatted_text("tag", "display", "Lore")
  end
end

