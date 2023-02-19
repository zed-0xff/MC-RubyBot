#!/usr/bin/env ruby
require_relative 'lib/common'

# 1 EGC = 32 GC + 128 EC
# 1 GC  =  1 C  +   8 GN
# 9 GN  =  1 GI

RESULT_SLOT_ID = 23
QUICKCRAFT_SLOTS = [16, 25, 34]

def craft! dst, recipe = []
  puts "[d] crafting #{dst} .."
  screen = open_screen("Craft Item", command: "/craft")

  tmp_moved = false
  if player.inventory.full?
    first_player_slot = MC.screen.slots.find{ |slot| slot.inventoryId == 'player' }
    first_player_slot.quick_move!
    tmp_moved = true
  end

  wait_for { !MC.screen.slots[QUICKCRAFT_SLOTS.first].empty? }
  QUICKCRAFT_SLOTS.each do |slot_id|
    if MC.screen.slots[slot_id].stack&.is_a?(dst)
      MC.screen.slots[slot_id].quick_move!
      MC.screen.slots[10].quick_move! if tmp_moved
      return
    end
  end
  raise "no recipe and no QC for #{dst.inspect}" if recipe.empty?

  # TODO: move all in one script
  used_slots = []
  recipe.each do |src|
    id, count = src.split(":")
    count = count.to_i
    # TODO: split stacks if count < stack_size
    slots = screen.player_slots.
      find_all { |s| s.stack&.skyblock_id == id && s.stack.count >= count }.
      delete_if { |s| used_slots.include?(s.id) }
    slot = slots.first
    raise "no #{src} !" unless slot
    slot.quick_move!
    used_slots << slot.id
  end
  wait_for { MC.screen && MC.screen.slots[RESULT_SLOT_ID].stack.is_a?(dst) }
  MC.screen.slots[RESULT_SLOT_ID].quick_move!
end

def create_gn amount
  needed_ingots = (amount/9.0).ceil
  while (delta = (needed_ingots-player.inventory.count("GOLD_INGOT"))) > 0
    puts "[.] need #{delta} ingots"
    exit unless @mining_sack.get_stack_of :gold_ingot
  end
  craft! "GOLD_NUGGET", ["GOLD_INGOT:#{needed_ingots}"]
end

def get_carrots amount
  needed_carrots = amount
  while (delta = (needed_carrots-player.inventory.count("CARROT_ITEM"))) > 0
    puts "[.] need #{delta} carrots"
    if delta/64 > player.inventory.free_slots_count
      raise "no carrots" unless @agro_sack.get_max_of :carrot
      break
    else
      raise "no carrots" unless @agro_sack.get_stack_of :carrot
    end
    break if player.inventory.full?
  end
end

def create_gc amount
  needed_nuggets = amount*8
  while (delta = (needed_nuggets-player.inventory.count(:gold_nugget))) > 0
    puts "[.] need #{delta} nuggets"
    create_gn(delta)
  end
  get_carrots amount

  while player.inventory.count("GOLDEN_CARROT") < amount
    craft! "GOLDEN_CARROT", [
      "GOLD_NUGGET:64", "GOLD_NUGGET:64", "GOLD_NUGGET:64",
      "GOLD_NUGGET:64", "CARROT_ITEM:64", "GOLD_NUGGET:64",
      "GOLD_NUGGET:64", "GOLD_NUGGET:64", "GOLD_NUGGET:64",
    ]
  end
end

def create_ec amount
  while (delta = (amount-player.inventory.count("ENCHANTED_CARROT"))) > 0
    puts "[.] need #{delta} enchanted carrots"
    break unless @e_agro_sack.get_stack_of :carrot
  end
  while (delta = (amount-player.inventory.count("ENCHANTED_CARROT"))) > 0
    # need to enchant
    puts "[.] need to make #{delta} enchanted carrots"
    needed_carrots = delta * 160
    get_carrots needed_carrots
    craft! "ENCHANTED_CARROT"
  end
end

@mining_sack = player.sacks.find{ |s| s.name =~ /\w+ Mining Sack$/ }
@agro_sack   = player.sacks.find{ |s| s.name =~ /\w+ Agronomy Sack$/ }
@e_agro_sack = player.sacks.find{ |s| s.name =~ /Enchanted Agronomy Sack$/ }

loop do
  # 2x amount for now bc splitting stacks is unimplemented
  create_ec(128)
  create_gc(32)
  craft! "ENCHANTED_GOLDEN_CARROT"
  sleep 0.2
end
