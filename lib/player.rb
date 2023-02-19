# frozen_string_literal: true
require_relative 'base'
require_relative 'sack'

class Player < Base
  attr_accessor :money, :mana, :max_mana, :hp, :max_hp, :profile_name

  HOTBAR_SLOTS = 0..7

  def initialize status
    super status['player']
    if status['sidebar']
      if (purse = status['sidebar'].find{ |x| x.start_with?("Purse: ") })
        @money = purse.split[1].tr(',','').to_f
      end
      @bingo = status['sidebar'].find { |x| x['Ⓑ Bingo'] }
    end
    if status['overlay'].to_s =~ /§c([0-9,]+)\/([0-9,]+)❤/
      @hp  = $1.tr(',','').to_i
      @max_hp = $2.tr(',','').to_i
    else
      @hp = @max_hp = -1
    end
    if status['overlay'].to_s =~ /§b([0-9,]+)\/([0-9,]+)✎ Mana/
      @mana = $1.tr(',','').to_i
      @max_mana = $2.tr(',','').to_i
    else
      @mana = @max_mana = -1 
    end
    if status.dig('playerList', 61).to_s =~ /^Profile:/
      @profile_name = status.dig('playerList', 61).split[1]
    end
  end

  # FIXME
  def ironman?
    false
  end

  def bingo?
    @bingo
  end

  def hp_percent
    100.0 * hp / max_hp
  end

  def data_dir
    @data_dir ||= File.join(*["data", uuid, profile_name].compact)
  end

  def inventory
    #@inventory ||= Inventory.new(@data['nbt']['Inventory'], player.dig('hotbar', 'selectedSlot'))
    @inventory ||= Inventory.new(@data['inventory'], self.dig('hotbar', 'selectedSlot'))
  end

  def hotbar
    inventory[HOTBAR_SLOTS]
  end

  # non-hotbar
  # 8 is unmovable 'Skyblock Menu'
  def main_inventory
    inventory[9..-1]
  end

  # deprecated
  def inventory_hash
    @inventory_hash ||= Hash[*@data['nbt']['Inventory'].map { |x| [x['Slot'], ItemStack.new(x)] }.flatten]
  end

  def has? x
    matcher = item_matcher(x)
    inventory.find{ |x| matcher.call(x) }
  end

  def has_in_hotbar? x
    matcher = item_matcher(x)
    hotbar.find{ |x| matcher.call(x) }
  end

  def fishHook
    @data['fishHook']
  end
  
  def facing
    @data['horizontalFacing']
  end

  def pos
    Pos[@data['pos']]
  end

  def block_pos
    Pos[@data['pos']].to_i!
  end

  def current_tool
    inventory[ self.dig('hotbar', 'selectedSlot') ]
  end
  alias :current_stack :current_tool

  def sacks
    # XXX will not be autoupdated on new sack
    @sacks ||= _list_sacks
  end

  def _list_sacks filter=nil
    r = []
    open_screen("Sack of Sacks", command: "/sacks") do |sacks_screen|
      sacks_screen.nonplayer_slots.each do |sacks_slot|
        next if sacks_slot.empty?
        skyblock_id = sacks_slot.stack.skyblock_id.to_s
        if skyblock_id =~ /_SACK$/
          next if filter && !skyblock_id[filter]
          r << Sack.new(sacks_slot.stack.uuid, sacks_slot.stack.display_name)
        end
      end
    end
    @nsacks = r.size
    r
  end

  # TBD
#  def organize_inventory!
#    # slot numbers in inventory and nbt->Inventory differ!
#    not_full_stacks = Hash.new{ |k,v| k[v] = [] }
#    @data['inventory'].each_with_index do |slot_data, slot_id|
#      stack = ItemStack.new(slot_data.merge({'Slot' => slot_id}))
#      next if stack.empty?
#      if stack.size < stack.max_size
#        not_full_stacks[stack.skyblock_id] << stack
#      end
#    end
#    not_full_stacks.each do |_, stacks|
#      if stacks.size > 1
#        stacks.each do |stack|
#          printf "[.] slot %2d: %2d/%2d %s\n", stack.slot_id, stack.size, stack.max_size, stack.display_name
#        end
#        MC.script do
#          click_inventory_slot! stacks[1].slot_id
#          click_inventory_slot! stacks[0].slot_id
#        end
#      end
#    end
#  end

end

