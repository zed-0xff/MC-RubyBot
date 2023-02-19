#!/usr/bin/env ruby
require_relative 'lib/common'
require_relative 'lib/sack'
require 'fileutils'
require 'yaml'

MC.exit_on_esc = false

class TotalInventory
  IGNORE_ITEMS = %w'SKYBLOCK_MENU'
  SACKS_RECOUNT_PERIOD = 60*60

  SUPPORTED_SCREENS = [
      /^Accessory Bag/,
      "Pets",
      "Potion Bag",
      "Personal Vault",
      "Quiver",
      "Sack of Sacks",
      "Trick or Treat Bag",
      /Backpack \(/,
      /^Ender Chest/,
      /^Wardrobe /,
  ]

  attr_accessor :data

  def initialize quiet: false
    @prev_inventory_data = nil
    @prev_screen_data = nil
    @quiet = quiet
  end

  def data_fname
    @data_dir ||= MC.player.data_dir
    FileUtils.mkdir_p(@data_dir) unless Dir.exist?(@data_dir)
    File.join @data_dir, "total_inventory.yml"
  end

  def data
    if @data
      @data
    else
      @data = File.exist?(data_fname) ? YAML::load_file(data_fname, permitted_classes: [Time]) : {
        "last_sacks_recount" => 0,
        "containers" => {},
        "timestamps" => {},
      }
    end
  end

  def timestamps
    data["timestamps"]
  end

  def process_chest screen
    if MC.current_zone != "Your Island"
      puts "[-] ignoring chest not on Private Island" unless @quiet
      return
    end
    if !(chest=MC.player.looking_at.dig('block')) || chest['id'] != "minecraft:chest"
      return
    end

    chest_id = nil
    typefacing = [chest['type'], chest['facing']].join(":")
    case typefacing
    when /^SINGLE/
      chest_id = "chest@" + chest['pos'].values.map(&:to_s).join(",")

    when "LEFT:east"
      chest_id = "chest@" + chest['pos'].values.map(&:to_s).join(",")
    when "RIGHT:east"
      chest['pos']['z'] -= 1
      chest_id = "chest@" + chest['pos'].values.map(&:to_s).join(",")

    when "LEFT:west"
      chest['pos']['z'] -= 1
      chest_id = "chest@" + chest['pos'].values.map(&:to_s).join(",")
    when "RIGHT:west"
      chest_id = "chest@" + chest['pos'].values.map(&:to_s).join(",")

    when "LEFT:north"
      chest_id = "chest@" + chest['pos'].values.map(&:to_s).join(",")
    when "RIGHT:north"
      chest['pos']['x'] -= 1
      chest_id = "chest@" + chest['pos'].values.map(&:to_s).join(",")

    when "LEFT:south"
      chest['pos']['x'] -= 1
      chest_id = "chest@" + chest['pos'].values.map(&:to_s).join(",")
    when "RIGHT:south"
      chest_id = "chest@" + chest['pos'].values.map(&:to_s).join(",")

    else
      puts "[?] unknown chest typefacing: #{typefacing}".yellow
      return
    end

    h = Hash.new(0)
    screen.nonplayer_slots.each do |slot|
      next if slot.empty?
      id = slot.stack.skyblock_id
      next if !id || IGNORE_ITEMS.include?(id)
      h[id] += slot.stack.count
    end
    return if h.empty? && !data["containers"][chest_id]
    return if data["containers"][chest_id] == h
    puts "[.] updated #{chest_id}" unless @quiet
    update chest_id, h
  end

  def process_minion screen
    minion_item = screen.slots[4].stack
    return unless (skyblock_id = minion_item.skyblock_id)
    unless skyblock_id =~ /GENERATOR/
      puts "[?] process_minion: unexpected id: #{skyblock_id.inspect}"
      return
    end
    e = MC.player.looking_at.dig('entity')
    if !e || e['id'] != "minecraft:armor_stand"
      puts "[?] not looking at minion?"
      return
    end
    minion_id = "minion@" + e['pos'].values.map(&:to_s).join(",")
    if minion_id.to_s == ""
      puts "[?] blank minion uuid"
      return
    end
    h = { skyblock_id => 1 }
    update minion_id, h
  end

  def process_screen screen
    fixed_title = fix_title(screen.title)
    h = Hash.new(0)
    case fixed_title
    when /Sack$/
      puts "[.] processing #{fixed_title}" unless @quiet
      h = Sack.count_items
    when *SUPPORTED_SCREENS
      puts "[.] processing #{fixed_title}" unless @quiet
      screen.nonplayer_slots.each do |slot|
        next if slot.empty?
        id = slot.stack.skyblock_id
        next if !id || IGNORE_ITEMS.include?(id)
        h[id] += slot.stack.count
      end
    when "Chest", "Large Chest"
      return process_chest(screen)
    when / Minion /
      return process_minion(screen)
    end
    return if h.empty? && !data["containers"][fixed_title]
    return if !data["containers"][fixed_title] == h
    update fixed_title, h
  end

  def process_inventory
    h = Hash.new(0)
    MC.player.inventory.each do |stack|
      id = stack.skyblock_id
      next if !id || IGNORE_ITEMS.include?(id)
      h[id] += stack.count
    end
    return if data["containers"]["inventory"] == h
    update "inventory", h
  end

  def update container_id, h, save: true
    old = data["containers"][container_id] || {}
    new = h
    unless @quiet
      (old.keys + new.keys).sort.uniq.each do |k|
        delta = new[k].to_i - old[k].to_i
        next if delta == 0
        if delta > 0
          printf "[+] %4d %-20s".greenish,   delta, ItemDB.id2name(k)
        else
          printf "[-] %4d %-20s".yellowish, -delta, ItemDB.id2name(k)
        end
        if timestamps[container_id]
          per_sec = delta.abs / (Time.now - timestamps[container_id])
          printf " %2d/min".gray, per_sec*60
        end
        $stdout << "\n"
      end
    end
    data["containers"][container_id] = h
    timestamps[container_id] = Time.now
    save! if save
  end

  def fix_title title
    title.
      sub(/^\w+ Backpack \(Slot #(\d+)\)$/, 'Backpack (\1/X)').
      sub(/^\w+ Backpack \((\d+)\/.*$/, 'Backpack (\1/X)').
      sub(%r|/\d+|, "/X").
      sub(%r|\s+\(1/X\)$|, "")
  end

  def save!
    totals = Hash.new(0)
    data['containers'].keys.each do |title|
      fixed_title = fix_title(title)
      if fixed_title != title
        puts "[*] renaming container #{title.inspect} -> #{fixed_title.inspect}"
        data['containers'][fixed_title] = data['containers'][title]
        data['containers'].delete(title)
      end
    end
    data['containers'].each do |_, cdata|
      cdata.each do |id, count|
        totals[id] += count
      end
    end
    data['total'] = totals
    File.write data_fname, data.to_yaml
  end

  def recount_sacks!
    #return # XXX
    MC.player.sacks.each do |sack|
      # XXX assuming there's only one of each sack types
      # because there's no way to get sack UUID from alrady opened sack screen
      sack_id = sack.name.sub(/^(Small|Medium|Large) /,'')
      next if timestamps[sack_id] && Time.now - timestamps[sack_id] < SACKS_RECOUNT_PERIOD
      update(sack_id, sack.count_items, save: false)
    end
    data["last_sacks_recount"] = Time.now.to_i
    MC.close_screen!
    save!
  end

  def tick screen: MC.screen, player: MC.player
    if screen
      if @prev_screen_data != screen.data
        process_screen screen
        @prev_screen_data = screen.data
      end
    end
    if @prev_inventory_data != player.inventory.data
      process_inventory
      @prev_inventory_data = player.inventory.data
    end
  end

  def loop!
    if Time.now.to_i - data["last_sacks_recount"].to_i > SACKS_RECOUNT_PERIOD
      recount_sacks!
    end

    loop do
      screen = wait_for_screen /./, msg: "containers", max_wait: nil
      tick
      sleep 0.2
    end
  rescue Interrupt
    exit
  end
end # class TotalInventory

if $0 == __FILE__
  TotalInventory.new.loop!
end
