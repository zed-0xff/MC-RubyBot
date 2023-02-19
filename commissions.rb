#!/usr/bin/env ruby
require_relative 'mine_static'
require_relative 'farm_mobs'

def warp_to_mines
  5.times do
    break if MC.current_map == 'Dwarven Mines'
    MC.chat! '/warp forge'
    sleep 3
  end
  raise "wrong map" if MC.current_map != 'Dwarven Mines'
end

def commissions
  r = {}
  if MC.status['playerList'].join("\n") =~ /^Commissions.+?\n\n/m
    r = Hash[$&.strip.split("\n")[1..-1].map{ |x| x.strip.split(": ") }]
  end
  r.delete 'Goblin Raid Slayer'
  r.delete 'Raffle'
  r.delete 'Lucky Raffle'
  if r.keys.count{ |k| k =~ /(Mithril|Titanium)$/ } > 0
    # will be completed by other mining commissions
    r.delete 'Mithril Miner'
    r.delete 'Titanium Miner'
  end
  r
end

EMISSARIES_IDS = 78..82

def call_emissary
  if MC.player.has?("ROYAL_PIGEON")
    with_tool("ROYAL_PIGEON") do
      MC.interact_item!
    end
  elsif MC.player.has?(/ABIPHONE/)
    with_tool(/ABIPHONE/) do
      MC.interact_item!
      wait_for { MC.screen && MC.screen.title =~ /Abiphone/ }
      MC.screen.click_on /Queen/
      sleep 3
    end
  else
    emissaries = MC.get_entities!(type: "OtherClientPlayerEntity", radius: 100)['entities'].
      find_all{ |e| EMISSARIES_IDS.include?(e['network_id']) }.
      sort_by{ |e| distance(e['pos']) }
    e = emissaries.first
    unless e
      MC.chat! "#goto 43 134 20"
      sleep 30
      return call_emissary
    end
    if distance(e['pos']) > 3
      MC.chat! "#goto " + e['pos'].values.map(&:to_s).join(' ')
      wait_for(max_wait: 30){ distance(e['pos']) < 2 }
      MC.chat! "#stop"
    end
    MC.interact_entity! uuid: e['uuid']
  end
  sleep 2
  MC.close_screen!
end

def goto target
  return if @last_goto == target
  unstash!("PREHISTORIC_EGG")
  @last_goto = target
  speedup!
  select_tool("HUNTER_KNIFE")
  MC.chat! "#wp goto " + target.downcase.tr(" ", "_").tr("'","")
  wait_for(max_wait: 120, raise: false){ MC.current_zone == target }
  wait_for(max_wait: 60, raise: false){ MC.player.speed == 0 }
  stash!("PREHISTORIC_EGG")
end

def do_commission
  a = commissions.
    sort_by{ |k,v| k =~ /(Titanium|Mithril)$/ ? 0 : 1 }.
    map(&:first)
  a.each do |c|
    case c
    when /^(.+) (Mithril|Titanium)$/
      zone = $1
      goto zone
      mine_static! while MC.current_zone == zone && !commissions.values.include?("DONE")
    when /^(Mithril|Titanium) Miner$/
      zone = "Rampart's Quarry"
      goto zone
      mine_static! while MC.current_zone == zone && !commissions.values.include?("DONE")
    when 'Ice Walker Slayer'
      zone = "Great Ice Wall"
      goto zone
      farm_mobs(filter: /Ice/) while MC.current_zone == zone && !commissions.values.include?("DONE")
    when 'Goblin Slayer'
      zone = "Goblin Burrows"
      goto zone
      farm_mobs while MC.current_zone == zone && !commissions.values.include?("DONE")
#    when 'Lucky Raffle'
      # get 25 tickets
#    when 'Raffle'
      # participate in raffle
    when 'Raid'
      while !commissions.values.include?("DONE") && MC.status['bossBars'].any?{ |b| b['name'] =~ /Raid in (.+)$/ }
        zone = $1
        goto zone if MC.current_zone != zone
        farm_mobs
      end
    end
    break if commissions.values.include?("DONE")
  end
end

def change_server
  MC.chat! "/warp home"
  sleep 5
  warp_to_mines
end

if $0 == __FILE__
  MC.chat! "#set logAsToast true"
  MC.chat! "#set freeLook false"
  MC.chat! "#set allowBreak false"
  MC.close_screen!

  begin
    loop do
      warp_to_mines
      respect_player
      if commissions.values.include?("DONE")
        @last_goto = 'emissary'
        call_emissary
        if rand(10) == 1
          change_server
        end
      end
      do_commission
    end
  ensure
    MC.chat! "#stop"
  end
end
