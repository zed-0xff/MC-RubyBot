#!/usr/bin/env ruby
require_relative 'lib/common'
require_relative 'lib/sack'
require_relative 'lib/helpers/compactor_helper'

MIN_COUNT_TO_ENCHANT = Hash.new(64*5)
MIN_COUNT_TO_ENCHANT["MELON"] = 64*9
MIN_COUNT_TO_ENCHANT["WHEAT"] = 64*9
MIN_COUNT_TO_ENCHANT["LEATHER"] = 64*9
MIN_COUNT_TO_ENCHANT["HARD_STONE"] = 64*9
MIN_COUNT_TO_ENCHANT["ENDER_PEARL"] = 16*5
MIN_COUNT_TO_ENCHANT["STRING"] = 64*6

def min_count_to_enchant src_id
  case src_id
  when /_GEM$/
    16*5
  when /^ENCHANTED_/
    32*5
  else
    MIN_COUNT_TO_ENCHANT[src_id]
  end
end

RECIPES = {
  "CACTUS"      => false,
  "CARROT_ITEM" => "ENCHANTED_CARROT",
  "POTATO_ITEM" => "ENCHANTED_POTATO",
  "ENDER_STONE" => "ENCHANTED_ENDSTONE",
  "GOLD_INGOT"  => "ENCHANTED_GOLD",
  "GRAVEL"      => false,
  "INK_SACK:2"  => "ENCHANTED_CACTUS_GREEN",
  "INK_SACK:3"  => "ENCHANTED_COCOA",
  "INK_SACK:4"  => "ENCHANTED_LAPIS_LAZULI",
  "IRON_INGOT"  => "ENCHANTED_IRON",
  "LOG:1"       => "ENCHANTED_SPRUCE_LOG",
  "LOG:2"       => "ENCHANTED_BIRCH_LOG",
  "LOG:3"       => "ENCHANTED_JUNGLE_LOG",
  "LOG"         => "ENCHANTED_OAK_LOG",
  "LOG_2"       => "ENCHANTED_ACACIA_LOG",
  "LOG_2:1"     => "ENCHANTED_DARK_OAK_LOG",
  "MELON"       => "MELON_BLOCK",
  "QUARTZ"      => false,
  "RAW_FISH:1"  => "ENCHANTED_RAW_SALMON",
  "RAW_FISH:2"  => "ENCHANTED_CLOWNFISH",
  "RAW_FISH:3"  => "ENCHANTED_PUFFERFISH",
  "STARFALL"    => false,
  "STONE"       => false,
  "SUGAR_CANE"  => "ENCHANTED_SUGAR",
  "SULPHUR"     => "ENCHANTED_GUNPOWDER",
  "TITANIUM_ORE"=> "ENCHANTED_TITANIUM",
  "WHEAT"       => "HAY_BLOCK",

  "PRISMARINE_SHARD" => false, # consumed by prismarine bow

  "ENCHANTED_DIAMOND"      => "ENCHANTED_DIAMOND_BLOCK",
  "ENCHANTED_IRON"         => "ENCHANTED_IRON_BLOCK",
  "ENCHANTED_GOLD"         => "ENCHANTED_GOLD_BLOCK",
  "ENCHANTED_ICE"          => "ENCHANTED_PACKED_ICE",
  "ENCHANTED_LAPIS_LAZULI" => "ENCHANTED_LAPIS_LAZULI_BLOCK",
  "ENCHANTED_REDSTONE"     => "ENCHANTED_REDSTONE_BLOCK",
}

GEMSTONE_TYPES = %w'JADE AMBER TOPAZ SAPPHIRE AMETHYST JASPER RUBY OPAL'
GEMSTONE_SIZES = %w'ROUGH FLAWED FINE FLAWLESS'

GEMSTONE_TYPES.each do |type|
  2.times do |i|
    src_id = [GEMSTONE_SIZES[i], type, "GEM"].join("_")
    dst_id = [GEMSTONE_SIZES[i+1], type, "GEM"].join("_")
    RECIPES[src_id] = dst_id
  end
end

SOURCE_SLOTS     = [10, 11, 12, 19, 20, 21, 28, 29, 30]
QUICKCRAFT_SLOTS = [16, 25, 34]

def close_screen
  MC.screen&.close!
end

def _enchant! src_stack, src_pre_count
#  puts "[d] enchant #{src_stack.inspect} #{src_count}"
  screen = open_screen("Craft Item", command: "/craft")
  wait_for(max_wait: 0.3, raise: false) { !MC.screen.slots[16].stack.empty? }
  src_skyblock_id = src_stack.skyblock_id
  dst_skyblock_id = RECIPES[src_skyblock_id] || "ENCHANTED_#{src_skyblock_id}".sub(/_ORE$/,'')
  quick_craft_slot_id = nil

  if src_skyblock_id == "WHEAT"
    moved_qty = 0
    MC.screen.player_slots.each do |slot|
      if slot.stack && slot.stack.is_a?(:wheat)
        moved_qty += slot.stack.size
        slot.quick_move!
        break if moved_qty == 64*9
      end
    end
    if moved_qty < 64*9
      nslots_to_fill = (64*9-moved_qty)/64
      nslots_to_fill.times do |i|
        wait_for { MC.screen }
        MC.screen.slots[SOURCE_SLOTS[i]].click! button: RIGHT
        MC.screen.slots[SOURCE_SLOTS[8-i]].click!
      end
    end
    quick_craft_slot_id = 23
    wait_for(max_wait: 1) { MC.screen && MC.screen.slots[quick_craft_slot_id].stack.is_a?(:hay_block) }
  elsif dst_skyblock_id
    QUICKCRAFT_SLOTS.each do |slot_id|
      expected_result = MC.screen.slots[slot_id].stack
      if expected_result.skyblock_id == dst_skyblock_id
        quick_craft_slot_id = slot_id
        break
      end
    end
  else
    src_pre_count = MC.player.inventory.count(src_skyblock_id)
    QUICKCRAFT_SLOTS.each do |slot_id|
      expected_result = MC.screen.slots[slot_id].stack
      if expected_result.id == src_stack.id
        dst_skyblock_id = expected_result.skyblock_id
        quick_craft_slot_id = slot_id
        break
      end
    end
  end

  tmp_moved = false

  if quick_craft_slot_id
    while MC.player.inventory.full?
      wait_for { MC.screen }
#      first_player_slot = MC.screen.slots.find{ |slot| slot.inventoryId == 'player' }
#      first_player_slot.quick_move!
      MC.screen.player_slots[1].quick_move! # XXX should be slot 0, but 1 is tmp for Armadillo bug workaround
      tmp_moved = true
      sleep 0.1
    end
  else
    # slow craft
    moved_qty = 0
    slots = []
    MC.screen.player_slots.each do |slot|
      stack = slot.stack
      if stack && stack.is_a?(src_stack.skyblock_id) && stack.count == stack.max_count
        slots << slot.id
        moved_qty += slot.stack.size
        break if moved_qty >= min_count_to_enchant(src_stack.skyblock_id)
      end
    end
    if slots.size < 5
      puts "[?] expected 5+ stacks of #{src_stack.skyblock_id}, but got #{slots.size}"
      return false
    end
    slots.each do |slot_id|
      MC.click_screen_slot! slot_id, action_type: "QUICK_MOVE"
    end
    quick_craft_slot_id = 23
    wait_for(max_wait: 1) { MC.screen && MC.screen.slots[quick_craft_slot_id].stack.is_a?(dst_skyblock_id) }
#    puts "[?] can't find needed recipe slot: #{src_skyblock_id}".red
#    sleep 1
#    return false
  end
  $stdout << "[*] crafting #{MC.screen.slots[quick_craft_slot_id].stack.display_name(color: true)} .. "

#  src_pre_count ||= MC.player.inventory.count(src_skyblock_id)
  dst_pre_count = MC.player.inventory.count(dst_skyblock_id)
  MC.screen.slots[quick_craft_slot_id].quick_move!
  MC.screen.slots[10].quick_move! if tmp_moved
  
  sleep 0.07

  dst_post_count = nil
  wait_for(max_wait: 1) do
    dst_post_count = MC.player.inventory.count(dst_skyblock_id)
    src_post_count = MC.player.inventory.count(src_skyblock_id)
    if MC.screen && MC.screen.slots[10].stack&.skyblock_id == dst_skyblock_id
      dst_post_count += MC.screen.slots[10].stack.size
    end
    dst_post_count > dst_pre_count && src_post_count < src_pre_count
  end
  puts "got #{dst_post_count-dst_pre_count} !"
  MC.invalidate_cache!
  true
end

def has_compactor_for? dst_id
  CompactorHelper.read_cache.values.flatten.include?(dst_id)
#  MC.player.inventory.
#    find_all{ |stack| stack.skyblock_id =~ /^PERSONAL_COMPACTOR_/ }.
#    each do |compactor|
#      compactor.dig('tag', 'ExtraAttributes').each do |k,v|
#        return true if k =~ /^personal_compact_/ && v == dst_id
#      end
#    end
#  false
end

@slots_per_sack = {}

def get_from_sack! uuid
  open_screen("Sack of Sacks", command: "/sacks") do |sacks_screen|
    sacks_screen.slots.each do |sacks_slot|
      next unless sacks_slot.stack&.uuid == uuid
      @slots_per_sack[uuid] = 0
      sack = wait_for_screen(/Sack$/, msg: sacks_slot.stack.display_name(color: true)) { sacks_slot.click! button: RIGHT }
      if sack.click_on(:chest, raise: false) # insert back leftovers
        sleep 0.05 # might take some time
      end
      # wait till sack screen fully loaded
      while MC.screen.nonplayer_slots.any? { |slot| slot.stack.nil? }
        sleep 0.05
        MC.invalidate_cache!
      end

      MC.screen.nonplayer_slots.each do |sack_slot|
        stack = MC.screen.slots[sack_slot.id].stack
        next if !stack || stack.empty?
        lore = stack.lore
        next unless lore
        gemstone_size = "Rough"
        if lore['Gemstones']
          next unless lore =~ /Rough:\s+([\d,]+)[^\d]/
          stored = $1.tr(",","").to_i
          if stored < 16*5
            next unless lore =~ /Flawed:\s+([\d,]+)[^\d]/
            gemstone_size = "Flawed"
          end
        else
          next unless lore =~ /Stored:\s+([\d,]+)[^\d]\//
        end
        @slots_per_sack[uuid] += 1
        stored = $1.tr(",","").to_i
        printf "[.] %5d %s\n", stored, stack.display_name(color: true) if stored > 0
        #next if sack.title == "Foraging Sack" && stored < 2000
        dname = stack.display_name.
          sub(/^(\w+) Gemstones$/, "#{gemstone_size} \\1 Gemstone")
        skyblock_id = ItemDB.name2id(dname)

        next if skyblock_id =~ /^ENCHANTED/ && !RECIPES[skyblock_id]

        if stored > min_count_to_enchant(skyblock_id) && (dst_id=RECIPES[skyblock_id]) != false
          unless dst_id
            dst_id = "ENCHANTED_#{skyblock_id}".sub(/_ORE$/,'')
          end

          MC.invalidate_cache!
          pre_count_src = MC.player.inventory.count(skyblock_id)
          pre_count_dst = MC.player.inventory.count(dst_id)
          post_count_dst = nil
          sack_slot.click!
          if has_compactor_for?(dst_id)
            puts "[*] assuming compactor help .."
            sleep 0.1
            return true
          else
            # wait for item being moved
            # it also might be autoenchanted if player has autoenchanter
            # p [skyblock_id, dst_id]
#            prev_dline = nil
            wait_for(max_wait: 1) do
              post_count_src = MC.player.inventory.count(skyblock_id)
              post_count_dst = MC.player.inventory.count(dst_id)
#              dline = sprintf "[d] src: %d -> %d, dst: %d -> %d", 
#                pre_count_src, post_count_src,
#                pre_count_dst, post_count_dst
#              puts dline if dline != prev_dline
#              prev_dline = dline
              post_count_src > pre_count_src || post_count_dst > pre_count_dst
            end
          end
#          if post_count_dst > pre_count_dst || has_compactor_for?(dst_id)
#            wait_for do
#              post_count_dst = MC.player.inventory.count(dst_id)
#              post_count_dst > pre_count_dst
#            end
#            redo
#          end
          return true
        end
      end
      sleep 0.05
    end
  end
  false
rescue Timeout::Error => e
  puts "[!] #{e} (#{caller[0]})".red
  MC.close_screen!
  retry
end

def _enchant_inventory! close: true
  nretries = 0
  MC.player.inventory.count_items.each do |key, count|
    min_count = min_count_to_enchant(key)
    min_count /= 2 if min_count == 64*5
    if count > min_count && (key !~ /^ENCHANTED_/ || RECIPES[key])
      begin
        stack = MC.player.inventory.find{ |stack| stack.skyblock_id == key }
        puts "[.] enchanting #{stack.display_name(color: true)} (#{count}) from inventory .."
        if _enchant!(stack, count)
          return true
        end
      rescue Timeout::Error => e
        puts "[!] #{e} (#{caller[0]})".red
        MC.close_screen!
        nretries += 1
        retry if nretries < 3
      end
    end
  end
  false
ensure
  if close
    MC.close_screen!
#    sleep 0.2
#    MC.lock_cursor!
  end
end

@nsacks = 0

def enchant_inventory! close: true
  loop do
    _enchant_inventory!(close: false) || break
  end
  open_screen("Sack of Sacks", command: "/sacks") do |sacks_screen|
    sacks_screen.click_on(:chest, raise: false)
    sleep 0.05
  end
  true
rescue => e
  $stderr.puts "[!] enchant_inventory!: #{e}"
ensure
  MC.close_screen! if close
end

def enchant_all! filter: nil
  enchant_inventory! close: false
  return if filter.to_s['inventory']

  MC.player.sacks.each do |sack|
    @nsacks += 1
    next if sack.name =~ /enchanted|slayer/i && sack.name != "Large Enchanted Mining Sack"
    next if filter && !sack.name[filter]
    loop do
      next if _enchant_inventory!(close: false)

#      if MC.player.inventory.free_slots_count < 10
#        puts "[!] need more free slots!".red
#        return false
#      end

      break unless get_from_sack!(sack.uuid)
    end
  end
ensure
  MC.close_screen!
end

def show_stats
  printf "[=] %d sacks, %d item types\n", @nsacks, @slots_per_sack.values.sum
end

#########

if $0 == __FILE__
  if ARGV.any?
    enchant_all! filter: /#{ARGV.first}/i
    show_stats
  else
    enchant_all!
    show_stats
  end
end
