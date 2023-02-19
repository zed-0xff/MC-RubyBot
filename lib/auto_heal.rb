# frozen_string_literal: true
require 'singleton'

class AutoHeal
  include Singleton

  attr_accessor :player

  def initialize
    @last_heals = Hash.new(Time.now - 1000)
  end

  def heal_with_zombie_sword!
    tool_id = /ZOMBIE_SWORD$/
    return unless player.has?(tool_id)
    if (player['health']['value'].to_f / player['health']['max'] < 0.8) && 
        (player.abilityCharges > 0 || (Time.now-@last_heals[tool_id] > 9.5)) &&
        (player.mana >= 50)
      MC.say! "[!] Medic!!!".red
      with_tool(tool_id) { MC.interact_item! }
      @last_heals[tool_id] = Time.now
    end
  end

  WANDS = {
    /WAND_OF_RESTORATION/ => 160,
    /WAND_OF_MENDING/ => 100,
    /WAND_OF_HEALING/ => 60,
  }

  def heal_with_wand!
    wand, min_mana = WANDS.find { |wand, min_mana| player.has?(wand) }
    return unless wand
    
    if ((1.0*player.hp/player.max_hp) < 0.8) && 
        (Time.now-@last_heals[wand] > 6) &&
        (player.mana >= min_mana)
      MC.say! "[!] Medic!!! (#{player.hp}/#{player.max_hp})".red
      with_tool(wand) { MC.interact_item! }
      @last_heals[wand] = Time.now
    end
  end

  def heal! player = MC.player
    @player = player
    heal_with_zombie_sword!
    heal_with_wand!
  end

  def self.heal! player = MC.player
    instance.heal!
  end
end
