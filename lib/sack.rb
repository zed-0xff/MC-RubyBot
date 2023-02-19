require_relative 'common'

class Sack
  attr_reader :uuid, :name

  def initialize uuid, name
    @uuid = uuid
    @name = name
  end
  
  def open!
    unless MC.screen && MC.screen.title == name.sub(/^(Small|Medium|Large) /, '')
      open_screen("Sack of Sacks", command: "/sacks", msg: nil) do |sacks_screen|
        slot = sacks_screen.slots.find { |slot| slot.stack&.uuid == uuid }
        wait_for_screen(/Sack$/, msg: nil) { slot.click! button: RIGHT }
      end
    end
  end

  def get item_id, button
    open!
    slot = wait_for { MC.screen.nonplayer_slots.find{ |slot| slot.stack&.id == "minecraft:#{item_id}" } }
    slot.stack.lore =~ /Stored:\s+([\d,]+)[^\d]\//
    stored = $1.tr(",","").to_i
    return false if stored == 0
    slot.click! button: button
    MC.invalidate_cache!
    sleep 0.1
    true
  end

  def get_max_of item_id
    get item_id, LEFT
  end

  def get_stack_of item_id
    get item_id, RIGHT
  end

  def count_items
    open!
    self.class.count_items
  end

  # assuming current screen is a sack
  def self.count_items
    r = {}
    screen = wait_for { MC.screen }
    screen.nonplayer_slots.each do |sack_slot|
      stack = screen.slots[sack_slot.id].stack
      next if !stack || stack.empty?
      lore = stack.lore
      next unless lore
      if lore['Gemstones']
        lore.scan(/(Rough|Fine|Flawed|Flawless):\s+([\d,]+)[^\d]/).each do |gemstone_size, count|
          count = count.to_i
          next if count == 0
          dname = stack.display_name.
            sub(/^(\w+) Gemstones$/, "#{gemstone_size} \\1 Gemstone")
          skyblock_id = ItemDB.name2id(dname)
          r[skyblock_id] = count
        end
      elsif lore =~ /Stored:\s+([\d,]+)[^\d]\//
        stored = $1.tr(",","").to_i
        next if stored == 0

        skyblock_id = ItemDB.name2id(stack.display_name)
        r[skyblock_id] = stored
      end
    end
    r
  end
end
