#!/usr/bin/env ruby
require 'yaml'
require_relative 'autoattack'

STDOUT.sync = true

MC.cache_ttl = 0.01
MC.exit_on_esc = false

class Brain
  ATTACK_PROB = 0.9 + rand()/10
  MINING_INERTIA = 10
  CONFIG_FNAME = "config.yml"

  ORES = {
    "minecraft:coal_ore" => true,
    "minecraft:diamond_block" => true,
    "minecraft:diamond_ore" => true,
    "minecraft:lapis_ore" => true,
    "minecraft:redstone_ore" => true,
    "minecraft:emerald_ore" => true,
    "minecraft:prismarine_bricks" => true, # mithril
    "minecraft:prismarine" => true, # mithril
    "minecraft:dark_prismarine" => true, # mithril
    "minecraft:stone" => true,
    "minecraft:cobblestone" => true,
  }

  CROPS = {
    "minecraft:carrots" => true,
    "minecraft:nether_wart" => true,
    "minecraft:wheat" => true,
    "minecraft:potatoes" => true,
    "minecraft:sugar_cane" => true,
  }

  WOODS = {
    "minecraft:acacia_wood" => true,
    "minecraft:acacia_log" => true,
    "minecraft:birch_wood" => true,
    "minecraft:birch_log" => true,
    "minecraft:jungle_wood" => true,
    "minecraft:jungle_log" => true,
    "minecraft:spruce_wood" => true,
    "minecraft:spruce_log" => true,
    "minecraft:dark_oak_wood" => true,
    "minecraft:dark_oak_log" => true,
    "minecraft:oak_wood" => true,
    "minecraft:oak_log" => true,
  }

  attr_accessor :keyDown

  def initialize
    @last_attack_tick = 0
    @last_mine_tick = 0
    @blind_attacks = 0
    @seen_mobs = {}
    @release_suppressed = false
    @keyDown = false
    @rules = read_rules
  end

  def read_rules
    @config_mtime = File.mtime(CONFIG_FNAME)
    rules = {}
    config = YAML::load_file( CONFIG_FNAME)
    config["rules"].each do |rulename, rule|
      rule['blocks'].each do |block|
        rules["minecraft:#{block}"] = Rule.new(rule, name: rulename, brain: self)
      end
    end
    puts "[.] got #{rules.size} rules from #{CONFIG_FNAME}"
    rules
  end

  class Rule
    attr_reader :name

    def initialize rule, name: nil, brain:
      @brain = brain
      @name = name
      @action = rule['action']
      @zones = rule['zones']
      @tool = rule['tool']
      @tool =
        case @tool
        when 'any'
          nil
        when %r|^:|
          @tool[1..-1].to_sym
        when %r|^/.+/$|
          Regexp.new(@tool[1..-2])
        else
          @tool
        end
    end

    def run! block
      if @zones && !@zones.include?(MC.current_zone)
        puts "[d] rule #{@name.inspect}: zone #{MC.current_zone.inspect} is not in #@zones"
        return
      end
      if @tool
        select_tool @tool
      end
      case @action
      when 'hold_left'
        unless @brain.keyDown
          press_key 'key.mouse.left'
          @brain.keyDown = true
        end
      when 'release_left'
        if @brain.keyDown
          release_key 'key.mouse.left'
          @brain.keyDown = false
        end
      else
        puts "[?] unknown action: #{@action.inspect}"
      end
    end
  end

  def is_crop id
    return false
    CROPS[id]
  end

  def is_ore id
    return false
    ORES[id]
  end

  def is_wood id
    return false
    WOODS[id]
  end

  # tick delta between attacks distribution recorded on 1000 real clicks:
  #
  #  0 0.07 ******
  #  1 0.05 ****
  #  2 0.06 ******
  #  3 0.46 *********************************************
  #  4 0.24 ***********************
  #  5 0.03 **
  #  6 0.01 *

  ATTACK_DISTRIBUTIONS = { 0 => 0.07, 1 => 0.05, 2 => 0.08, 3 => 0.50, 4 => 0.26, 5 => 0.03, 6 => 0.01 }
  def distributed_random(distributions)
    r = rand
    distributions.detect{ |k, d| r -= d; r < 0 }.first
  end

  # TODO:
  #   1. wait_ticks distribution
  #   2. start attacking even before entity is seen
  #   3. continue attacking for some time after entity seen
  #   4. hit/miss ratio: [=] 196 swings, 162 hits, ratio = 0.827
  #
  def smart_attack! blind: false
    if @next_attack_delay
      return if (MC.tick - @last_attack_tick) < @next_attack_delay
    end
    @next_attack_delay = distributed_random(ATTACK_DISTRIBUTIONS)

    if blind
      if @blind_attacks <=  0
        puts "[?] blind attacking with zero counter".yellow
        return
      end
      @blind_attacks -= 1
      #say "#{MC.tick} blind attack!"
      @last_attack_tick = MC.tick
      attack!
    elsif rand() < ATTACK_PROB
      @blind_attacks = rand(3)
      #say "#{MC.tick} attack!"
      @last_attack_tick = MC.tick
      attack!
    else
      #say "#{MC.tick} skip attack"
      # skip tick
      @last_attack_tick = MC.tick
    end
  end

  # level + progress => raw value
  # https://minecraft.fandom.com/wiki/Experience
  def exp_lp2raw level, progress
    total =
      case level
      when 0..16
        level**2 + 6*level
      when 17..31
        2.5*(level**2) - 40.5*level + 360
      else
        4.5*(level**2) - 162.5*level + 2220
      end

    to_next =
      case level
      when 0..16
        2*level + 7
      when 17..31
        5*level - 38
      else
        9*level - 158
      end

    total + to_next*progress
  end
    
  # count raw exp points gotten between two points
  def exp_diff a, b
    exp_lp2raw(*b) - exp_lp2raw(*a)
  end

  def process_block! block
    if is_ore(block['id'])
      @last_mine_tick = MC.tick
      return true if @release_suppressed
      mleft = MC.status.dig('input', 'key.mouse.left')
      if mleft['state'] == 1 && mleft['age'] < 5
        # FIXME
        select_slot 3 if player.inventory.selected_slot != 3
        # break_block!
        puts "[d] breaking block .."
        #press_key 'key.mouse.left'
        suppress_button_release!
        @release_suppressed = true
        #puts "return true"
        return true
      end
    elsif is_crop(block['id'])
      press_key 'key.mouse.left'
      @keyDown = true
      return true
    elsif is_wood(block['id'])
      # FIXME
      select_slot 5 if player.inventory.selected_slot != 5
      press_key 'key.mouse.left'
      @keyDown = true
      return true
    end
    #puts "return false"
    false
  end

  def think!
    prevline = nil
    @keyDown = false
    prevexp = nil

    status = wait_for(max_wait: nil) { MC.status }
    @start_tick = status['tick']
    register_command "status"
    say "[:] brain connected"

    loop do
      MC.invalidate_cache!
      autorun
      player = MC.player
      exp = [player.experienceLevel, player.experienceProgress]
      if exp != prevexp
        say("+%d exp" % exp_diff(prevexp, exp) ) if prevexp
        prevexp = exp
      end

      if (mob = player.dig('looking_at', 'entity')) && is_mob(mob)
        seen_this_mob_before = @seen_mobs.key?(mob['uuid'])
        line = shortstatus(mob)
        if line != prevline
          puts line
          prevline = line
        end
        # FIXME
        slot = mob['name'] == 'Ice Walker' ? 3 : 0
        select_slot slot if player.inventory.selected_slot != slot
        mleft = MC.status.dig('input', 'key.mouse.left')
        if mob.dig('nbt', 'Invisible') == 1
          say "[!] stop attacking invisible mob!"
          @blind_attacks = 0
        elsif (mleft['state'] == 0 && mleft['age'] < 7) || (seen_this_mob_before && hp(mob) > 0)
          @seen_mobs[mob['uuid']] = mob
          @last_attack_tick = MC.tick - mleft['age']
          outline_entity! mob['uuid']
          smart_attack!
        elsif @blind_attacks > 0
          @seen_mobs[mob['uuid']] = mob
          smart_attack! blind: true
        end
      elsif (MC.tick - @last_attack_tick) < 7 && (@blind_attacks > 0)
        # continue attacking to simulate real player behavior
        smart_attack! blind: true
        next
      end

      block = player.dig('looking_at', 'block')
      if block && (rule = @rules[block['id']])
        rule.run! block
      end

      if block && MC.current_zone != 'Your Island'
        process_block!(block)
      end
      if @release_suppressed && (MC.tick - @last_mine_tick) > MINING_INERTIA
        puts "[d] releasing suppress"
        @release_suppressed = false
        suppress_button_release! false
        #release_key 'key.mouse.left'
      end
      sleep 0.05 # ((5 + rand(6)) / 1000.0)
    end
  rescue Interrupt
    exit
  rescue => e
    puts "[!] #{e}".red
    e.backtrace.each do |line|
      puts "  #{line}"
    end
  end
end

if $0 == __FILE__
  loop do
    Brain.new.think!
    say "§c§l[!!!] brain disconnected!"
    sleep 5
  end
end
