#!/usr/bin/env ruby
require_relative 'farm_mobs'
require_relative 'mine_static'

BOSS_LEVEL = 1

def get_state
  lines = status['sidebar']
  lines.each_with_index do |line, idx|
    if line.strip == 'Slayer Quest'
      return lines[idx+2]
    end
  end
  @state
end

prevstate = nil
@last_call = Time.now - 10000

def call_maddox
  @state = nil
  @last_call = Time.now
  with_tool "AATROX_BATPHONE" do
    MC.interact_item!
  end

  msg = wait_for_message 'OPEN MENU', only_new: true
  return unless msg.to_s =~ /"(\/cb \h+-\h+-\h+-\h+-\h+)"/
  chat $1
  wait_for_screen /Slayer/
  if MC.screen.slots[13].is_a?(:red_terracotta)
    # quest failed
    MC.screen.slots[13].click!
  elsif MC.screen.slots[13].stack.lore =~ /You have an active Slayer quest/
    @state = ") Combat"
    MC.close_screen!
    # quest ongoing
    return
  else
    # success
    #exit
  end
  MC.screen.click_on :ender_pearl
  wait_for { MC.screen && MC.screen.slots[32].is_a?(:wheat) }
  wait_for_screen /Seraph/ do
    MC.screen.click_on :ender_pearl
  end
  wait_for_screen /Confirm/ do
    MC.screen.slots[10+BOSS_LEVEL].click!
  end
  MC.screen.click_on /Confirm/
  sleep 1
end

while MC.current_map == "The End"
  state = get_state

  if state != prevstate
    puts "[*] #{state}".white
    prevstate = state
  end

  if @state && Time.now - @last_call > 300
    @state = nil
  end

  case state
  when nil
    if Time.now - @last_call > 300
      puts "[.] Checking Maddox .."
      call_maddox
    end
  when /Slay the boss/
    unless farm_mobs(timeout: (0.3+rand()/10), range: 20..30, filter: /Seraph/)
      #farm_mobs(timeout: (0.2+rand()/10), range: 20..30, radiusY: 8, filter: /Jerry|Zealot|Enderman/)
    end
  when /\d+\/\d+ Kills/, /\) Combat/
    farm_mobs(timeout: (0.2+rand()/10), range: 20..30, radiusY: 8, filter: /Jerry|Zealot|Enderman/)
    #if !farm_mobs(timeout: (0.2+rand()/10), range: 20..30) && ARGV.any?
      #prev_slot = player.inventory.selected_slot
    #  sleep 0.5
      #mine_static!
      #select_slot prev_slot
    #end
  when /Boss slain/
    call_maddox
  else
    puts state
    exit
  end
end
