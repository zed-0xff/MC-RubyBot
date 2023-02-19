#!/usr/bin/env ruby
require_relative 'enchant'

# slots:
#   0 - processing item
#   1 - fuel
#   2 - result

def process! slot
  if !MC.screen.slots[0].empty? && !MC.screen.slots[2].empty?
    # move back already processed item on start
    MC.screen.slots[2].quick_move!
  end
  wait_for { MC.screen.slots[0].empty? }
  puts "[.] processing slot #{slot.index} .."
  slot.quick_move!
  wait_for { MC.screen.slots[0].empty? }
  sleep 0.3
  MC.screen.slots[2].quick_move!
  sleep 0.5
end

MC.cache_ttl = 0.1

def smelt_inventory
  was = false

  MC.screen.close! if MC.screen && MC.screen.title != 'Hyper Furnace'

  #look_at [-5.5, 100, 30] # smelter
  #press_key "key.mouse.right", 50
  if MC.player.dig('looking_at', 'block', 'id') == 'minecraft:furnace'
    MC.interact_block!
  end

  wait_for("furnace screen"){ MC.screen&.title == "Hyper Furnace" }
  slots = MC.screen.slots

  unless slots[2].empty?
    slots[2].quick_move!
  end

  slots[2..-1].each do |slot|
    next if slot.empty?
    #    printf "%2d %2d %s (%d)\n", slot.id, slot.index, slot.stack.id, slot.stack.count
    if slot.stack.id == "minecraft:cactus"
      was = true
      process! slot
    end
  end
  was
end

def move_from_sacks
  chat "/sacks"
  wait_for("sacks"){ MC.screen&.title == "Sack of Sacks" }
  MC.screen.click_on /Agronomy Sack/, button: RIGHT
  wait_for("agronomy sack"){ MC.screen&.title == "Agronomy Sack" }
  MC.screen.click_on :cactus
  sleep 0.1
  MC.screen.click_on /Back/
  wait_for("sacks"){ MC.screen&.title == "Sack of Sacks" }
  MC.screen.click_on /Close/
end

#########


smelt_inventory
loop do
  while player.inventory.full?
    enchant_inventory!
    sleep 1
  end
  move_from_sacks
  break unless smelt_inventory
end

