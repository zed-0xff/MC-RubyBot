#!/usr/bin/env ruby
require_relative 'farm_mobs'

TRAPPER_NETWORK_ID = 17

def is_trapper?(e)
  e['name'] == "Trevor The Trapper" || e['network_id'] == TRAPPER_NETWORK_ID
end

def interact_trapper!
  MC.chat! "#stop"

  e = MC.get_entities!(radius: 3)['entities'].find { |e| is_trapper?(e) }
  r = e && distance(e['pos']) < 2
  if r
    MC.interact_entity! uuid: e['uuid']
    return
  end

  loop do
    MC.chat! "/warp trapper"
    sleep 1
    messages = get_messages
    break if messages.none?{ |m| m['message'] =~ /You can't fast travel while in combat/ }
  end

  wait_for(max_wait: 8) do
    MC.get_entities!(radius: 8)['entities'].find { |e| is_trapper?(e) }
  end
  MC.chat! "#goto 281 104 -544"
  wait_for(max_wait: 8) do
    e = MC.get_entities!(radius: 3)['entities'].find { |e| is_trapper?(e) }
    r = e && distance(e['pos']) < 2
    if r
      MC.interact_entity! uuid: e['uuid']
    end
    r
  end
end

def goto_location! location
  case location
  when 'Oasis', 'Desert Settlement'
    MC.chat! "/warp desert"
  else
    speedup!
    MC.chat! "#wp goto #{location.downcase.tr(" ", "_")}"
  end
  sleep 1
end

def get_messages
  messages = MC.get_messages!(prev_index: @prev_index)['messages']
  if messages.any?
    @prev_index = messages.map{ |m| m['index'] }.max
  end
  messages
end

# start
MC.chat! "#stop"
if idx = MC.status['sidebar'].find_index("Tracker Mob Location:")
  @location = MC.status['sidebar'][idx+1]
  goto_location! @location
else
  interact_trapper!
end

# ignore all old messages
get_messages

loop do
  messages = get_messages
  unless messages.any?
    if MC.current_zone == @location && @type
      MC.chat! "#stop"
      farm_mobs(
        classes: %w'AnimalEntity',
        filter: /#{@type}/i,
        enchant: false,
        radiusY: 8,
        timeout: 0.2
      )
    else
      sleep 0.5
      next
    end
  end
  pp messages
  messages.uniq.each do |m|
    case m['message']
    when /Accept the trapper's task to hunt the animal\?/
      MC.chat! m['events'].first
      wait_for do
        messages = get_messages
        if (m = messages.find { |m| m['message'] =~ /You can find your (.+) animal near the (.+)\.$/ })
          @type = $1
          @location = $2
          MC.add_hud_text! ansi2mc("#{@type} @ #{@location}".green), x: -2, y: -1, key: "trapper", ttl: 600*MC::TICKS_PER_SEC
          goto_location! @location
          true
        else
          false
        end
      end
      break
    when /new animal to hunt!/
      sleep 1
      interact_trapper!
    when /Sorry, I don't have any animals for you to hunt/
      sleep 0.5+rand()*2
      interact_trapper!
    #when /You can find your (.+) animal near the (.+)\.$/
    end
  end
end
