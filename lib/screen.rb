class Screen < Base
  def title
    @data['title'].gsub(/§./,"")
  end

  def close!
    MC.close_screen!
  end

  def click_on target, button: LEFT, action_type: "PICKUP", raise: true, sleep: 0.05
    slot =
      case target
      when Symbol
        slots.find { |slot| !slot.empty? && slot.stack.id == "minecraft:#{target}" }
      when Regexp
        slots.find { |slot| !slot.empty? && slot.stack.dig('tag', 'display', 'Name') =~ target }
      else
        raise "unknown target type: #{target.inspect}"
      end
    if slot
      slot.click! button: button, action_type: action_type
      sleep(sleep)
      true
    elsif raise
      puts "[d] available slots:"
      slots.each do |slot|
        puts "  #{slot.stack.id}" if !slot.empty? && !slot.stack.id.end_with?('_glass_pane')
      end
      raise "slot #{target} not found"
    else
      false
    end
  end

  def sync_id
    @data.dig('handler', 'syncId')
  end

  def slots
    #@slots ||= 
    @data['slots'].map do |x|
      inventoryId = x['inventoryId']
      Slot.new(x).tap do |slot|
        slot.inventory = (inventoryId == 'player') ? MC.player.inventory_hash : @data['inventories'][inventoryId]
      end
    end
  end

  def nonplayer_slots
    @data['slots'].find_all { |x| x['inventoryId'] != 'player' }.map do |x|
      inventoryId = x['inventoryId']
      Slot.new(x).tap do |slot|
        slot.inventory = @data['inventories'][inventoryId]
      end
    end
  end

  def player_slots
    @data['slots'].find_all { |x| x['inventoryId'] == 'player' }.map do |x|
      Slot.new(x).tap do |slot|
        slot.inventory = MC.player.inventory
      end
    end
  end

  class Slot < Base
    attr_accessor :inventory

    def stack
      i = inventory[@data['index']]
      case i
      when Hash
        ItemStack.new(i)
      else
        i
      end
    end

    def clear!
      inventory[@data['index']] = nil
    end

    def empty?
      !stack || stack.empty?
    end

    def is_a? type
      stack && stack.is_a?(type)
    end

    def click! button: LEFT, action_type: "PICKUP", delay: 0.05
      MC.invalidate_cache!
      script = [{ command: "clickScreenSlot", intArg: self.id, intArg2: button, stringArg: action_type }]
      Net::HTTP.post(ACTION_URI, script.to_json)
      sleep(delay) if delay
    end

    def quick_move!
      click! button: LEFT, action_type: "QUICK_MOVE"
    end
  end # class Slot
end

