require 'json'
require 'uri'
require 'net/http'
require 'pp'
require 'open-uri'
require 'yaml'
require 'digest/md5'
require 'timeout'
require 'set'

require_relative 'colors'
require_relative 'pos'
require_relative 'inventory'
require_relative 'item_db'
require_relative 'item_stack'
require_relative 'mc'
require_relative 'player'
require_relative 'screen'
require_relative 'auto_heal'

class Array
  def random
    self[rand(size)]
  end
end

$stdout.sync = true

ACTION_URI = URI('http://127.0.0.1:9999/action')
LOG_FNAME = "~/minecraft/logs/latest.log"
BLOCK_REACHABLE_DISTANCE  = 4.49
ENTITY_REACHABLE_DISTANCE = 2.99
LEFT = 0
RIGHT = 1

def status
  MC.status
end

def player
  $stderr.puts "[!] use MC.player (#{caller[0]})".gray
  MC.player
end

def pos
  Pos.new status['player']['eyePos']
end

def hold_key key
  press_key key
  while yield 
    sleep 0.4
  end
ensure
  release_key key
end

def press_key key, delay_ = 0, delay: nil
  delay ||= delay_
  MC.invalidate_cache!
  key = "key.keyboard.#{key}" if key =~ /\A\w+\Z/
  script = [ { command: "key", stringArg: key, delay: delay } ]
  Net::HTTP.post(ACTION_URI, script.to_json)
end

def release_key key
  MC.invalidate_cache!
  key = "key.keyboard.#{key}" if key =~ /\A\w+\Z/
  script = [ { command: "key", stringArg: key, delay: -1 } ]
  Net::HTTP.post(ACTION_URI, script.to_json)
end

def auto_jump value
  script = [ { command: "setAutoJump", boolArg: value } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
end

def distance a, b=pos
  a = Pos[a]
  b = Pos[b]
  Math.sqrt((a.x-b.x)**2 + (a.y-b.y)**2 + (a.z-b.z)**2)
end

def look_at target, delay: nil
  puts "[.] use MC.look_at!".gray
  delay ||= (20+rand(20))
  target = Pos[target]
  script = [ { command: "lookAt", target: target.to_h, delay: delay } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
  r = JSON.parse(res.body)
  l = r.dig('player','looking_at')
  MC.status['player']['looking_at'] = l if MC.status
  MC.status['player']['pitch'] = r['player']['pitch']
  MC.status['player']['yaw'] = r['player']['yaw']
  l
end

AI_MAX_WAIT = 15.0 # seconds

def say what
  puts "[.] use MC.say!".gray
  MC.say! what
end

def chat what
  script = [ { command: "chat", stringArg: what } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
end

def get_messages filter
  script = [ { command: "messages", stringArg: filter } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
  JSON.parse(res.body)['messages']
end

def ai_move_to target
  raise "no AI!" unless MC.has_mod?('baritone')
  _ai_move_to target
end

def _ai_move_to target
  result = true
  MC.invalidate_cache!
  target = Pos[target]
  script = [ { command: "chat", stringArg: "#goto #{target.x.round(3)} #{target.y.round(3)} #{target.z.round(3)}" } ]
  res = Net::HTTP.post(ACTION_URI, script.to_json)
  t0 = Time.now
  dt = 0
  sleep 0.2
  dist = prev_dist = nil
  nticks = 0
  dlook = Pos[0, 1.2+rand()/6, 0]
  while (dt=Time.now - t0) < AI_MAX_WAIT
    dist = distance(target, pos)
    MC.look_at!(target + dlook) if dist > 2
    printf "\r[.] waiting for AI .. t=%5.3fs, dist=%.3f  ".purple, dt, dist
    if (dist < 1 || prev_dist == dist) && nticks > 10
      $stdout << "\n[?] ai stop: dist=#{dist} prev_dist=#{prev_dist} nticks=#{nticks}".yellowish
      result = false
      break
    end
    if block_given?
      break if yield 
    end
    break if player_acted?(['key.keyboard.w', 'key.keyboard.s', 'key.keyboard.a', 'key.keyboard.d'])
    sleep 0.2
    MC.invalidate_cache!
    prev_dist = dist
    nticks += 1
  end
  puts
  result = false if dt >= AI_MAX_WAIT
  result
ensure
  script = [ { command: "chat", stringArg: "#stop" } ]
  Net::HTTP.post(ACTION_URI, script.to_json)
end

def play_sound name
  script = [
    { command: "playSound", stringArg: name, floatArg: 1.0 },
  ]
  Net::HTTP.post(ACTION_URI, script.to_json).body
end

def left_click!
  script = [
    { command: "key", stringArg: "key.mouse.left", delay: 50+rand(10) }
  ]
  Net::HTTP.post(ACTION_URI, script.to_json).body
end

def break_block!
  script = [ { command: "breakBlock" } ]
  Net::HTTP.post(ACTION_URI, script.to_json).body
end

def right_click!
  script = [
    { command: "key", stringArg: "key.mouse.right", delay: 50+rand(10) }
  ]
  Net::HTTP.post(ACTION_URI, script.to_json).body
end

def select_slot n
  MC.select_slot! n
end

$last_speedup = Time.now - 1000
$last_speedup_server = nil
$last_knife_select= Time.now - 1000

def autorun force: false
  return if MC.current_zone == "Jungle Temple"
  if (ct = MC.player.current_tool)
    return if ct.is_a?("COCO_CHOPPER")
    return if ct.is_a?("DWARVEN_METAL_DETECTOR")
    return if ct.is_a?(/SHORTBOW/)
    return if ct.is_a?("PUMPKIN_DICER")
  end

  input = status['input']
  if force || ((input['key.keyboard.w']['state'] == 1) && 
      (input['key.keyboard.w']['age'] > 8) &&
      (input.dig('key.keyboard.left.shift', 'state') != 1) &&
      (input.dig('key.keyboard.left.control', 'state') != 1) &&
      (input['key.mouse.right']['state'] == 0))

    if (MC.player.mana >= 50) && 
        ( (Time.now - $last_speedup >= 28) || ($last_speedup_server != MC.current_server) ) &&
        ( MC.player.dig('nbt','abilities','walkSpeed') < 0.3 )
      speedup!
    end
    lok = input['key.mouse.left']['state'] == 0 && input['key.mouse.left']['age'] > 10
    rok = input['key.mouse.right']['state'] == 0 && input['key.mouse.right']['age'] > 10
    if force || (lok && rok && (Time.now-$last_knife_select) > 3 && !ct.is_a?("GRAPPLING_HOOK"))
      $pre_autorun_slot = MC.player.inventory.selected_slot
      if (tool = select_tool("HUNTER_KNIFE"))
        $post_autorun_slot = tool['Slot']
      end
      $last_knife_select = Time.now
    end
  elsif MC.status.dig('player', 'speed').to_i < 4.5
    # select pre-autorun tool
    if $pre_autorun_slot && ($pre_autorun_slot != $post_autorun_slot) && ($pre_autorun_slot != MC.player.inventory.selected_slot)

      select_slot $pre_autorun_slot
    end
    $pre_autorun_slot = nil
  end
end

# stacks possible in inventory where count is zero, but id is still kept
def item_matcher id
  case id
  when Regexp
    Proc.new { |x| x.count > 0 && x.skyblock_id =~ id && x.dig('nbt', 'ExtraAttributes', 'drill_fuel') != 0 } # XXX
  when /^[A-Z0-9_:]+$/
    # skyblock_id
    Proc.new { |x| x.count > 0 && x.skyblock_id == id }
  when Symbol
    # minecraft id
    id = "minecraft:#{id}"
    Proc.new { |x| x.count > 0 && x.id == id }
  else
    raise "[?] don't know how to find #{id.inspect}"
  end
end

def select_tool tool_id, delay_next: nil, return_tool: true
  matcher = item_matcher(tool_id)

  ct = MC.player.current_tool
  if ct && matcher.call(ct)
    return return_tool ? ct : false
  end

  tool = MC.player.hotbar.find{ |x| x && matcher.call(x) }

  if tool
    MC.select_slot! tool['Slot'], delay_next: delay_next
    return_tool ? tool : true
  else
    #puts "[?] tool #{tool_id.inspect} not found"
    nil
  end
end

def with_tool tool_id, delay_next: nil, select_previous: true
  prev_slot = MC.player.inventory.selected_slot
  matcher = item_matcher(tool_id)
  if (tool=MC.player.hotbar.find{ |x| matcher.call(x) })
    begin
      MC.select_slot! tool['Slot'], delay_next: delay_next
      yield
    ensure
      if select_previous
        MC.select_slot! prev_slot, delay_next: delay_next
      end
    end
    true
  else
    puts "[?] tool #{tool_id.inspect} not found"
    false
  end
end

def speedup!
  #return if (Time.now - $last_speedup < 30) && ($last_speedup_server == MC.current_server)
  return unless MC.player.has?("ROGUE_SWORD")
  return if MC.player['fishHook']

  r = with_tool("ROGUE_SWORD") do
    #release_key 'key.mouse.left'
    # XXX fix checking return result
    MC.interact_item!
  end
  if r
    puts "[*] speedup!".green
  else
    puts "[?] #{r}"
  end
  $last_speedup = Time.now
  $last_speedup_server = MC.current_server
end

def player_acted? keys = nil
  return false if !status || !status['input']
  if keys
    keys.any? { |key| status.dig('input', key, 'state') == 1 }
  else
    !status['input'].values.all? { |e| e['age'] > 10 && e['state'] != 1 }
  end
end

# resolution is 20 ticks per second
def respect_player delay: 2
  msg_shown = false
  return false if !status || !status['input']
  loop do
    #AutoHeal.heal!
    #autorun
    break if status['camera'] # camera detached
    break if status['input'].values.all? { |e| e['age'] > 10 && e['state'] != 1 }
    break if MC.screen
    unless msg_shown
      MC.say! "[-] respecting player .."
      msg_shown = true
    end
    sleep delay
  end
  MC.say! "[+] resuming operation .." if msg_shown
  msg_shown
end

def wait_for msg = nil, delay: 0.1, max_wait: 5, raise: true
  r = nil
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  puts("[w] waiting for #{msg.is_a?(Regexp) ? msg.source : msg} ..") if msg && !yield
  while !(r=yield)
    if max_wait && Process.clock_gettime(Process::CLOCK_MONOTONIC)-t0 > max_wait
      if raise
        raise Timeout::Error
      else
        return false
      end
    end
    MC.invalidate_cache!
    sleep 0.1
  end
  r
end

def is_current_screen? title
  re = case title
       when Regexp; title
       when String; /^#{Regexp.escape(title)}$/
       else
         raise "unknown title type: #{title.inspect}"
       end
  MC.screen&.title =~ re
end

def wait_for_screen title, delay: 0.1, msg: title, max_wait: 1, raise: true
  unless is_current_screen?(title)
    yield if block_given?
    unless wait_for(msg, max_wait: max_wait, raise: false){ is_current_screen?(title) }
      yield if block_given?
      wait_for(msg, delay: delay, raise: raise){ is_current_screen?(title) }
    end
  end
  MC.screen
end

def wait_for_message filter, max_wait: 5, only_new: false
  messages = nil
  prev_messages = only_new ? get_messages(filter) : []
  wait_for(max_wait: max_wait) do
    messages = get_messages(filter) - prev_messages
    messages.any?
  end
  messages.first
end

def log msg
  script = [
    { command: "log", stringArg: msg }
  ]
  Net::HTTP.post(ACTION_URI, script.to_json).body
end

def scan(
  radius: BLOCK_REACHABLE_DISTANCE,
  radiusY: BLOCK_REACHABLE_DISTANCE-1.5,
  offset: { x: 0, y: 1, z: 0 },
  expand: { x: radius, y: radiusY, z: radius }
)
  script = [
    { command: "blocksRelative",
      expand: expand,
      offset: offset,
    }
  ]
  JSON.parse Net::HTTP.post(ACTION_URI, script.to_json).body
end

def set_pitch_yaw pitch: nil, yaw: nil, delay: 20
  script = [
    { command: "setPitchYaw", floatArg: pitch || MC.player.pitch, floatArg2: yaw || MC.player.yaw, delay: delay }
  ]
  Net::HTTP.post(ACTION_URI, script.to_json)
end

# npc/player/mob/pet (there are zombie pets, or Jerry)
# too complex/fragile logic to implement it in java
def entity_kind entity
  return nil unless entity
  # if it has empty inventory => it's likely a NPC
  # 'fkt_Ice Walker', 'fkt_Goblin ' (with space)
  return :mob if entity['scoreboardTeam']&.start_with?("fkt_")

  # some "creeper"-like protection aura
  return :pet if entity.dig('nbt', 'Fuse') == 30
end

def is_player? entity
  (entity['id'] == "minecraft:player") &&
    # 'fkt_Ice Walker', 'fkt_Goblin ', 'fkt_Crystal Sent'
    #(!entity['scoreboardTeam']&.start_with?("fkt_")) &&
    (entity['scoreboardTeam'] =~ /^a-?\d+$/) &&
    # suppose there's no players with empty inventory and naked :)
    (entity.dig('nbt', 'Inventory')&.size.to_i > 0) #&&
    # all players items should have UUID, mobs may have 'generic' items
#    (entity.dig('nbt', 'Inventory').all? { |item| item.dig('tag', 'ExtraAttributes', 'uuid') })

  # also:
  #   - NPCs typically have label 'CLICK' on top of them
  #   - mobs have all items ExtraAttributes->timestamp equal
  #   - mobs have ArmorStands with title like "[Lv50] Star Sentry 10/10❤" on their top
  #   - for mobs:
  #      Array(entity.dig('nbt', 'Attributes')).map{ |a| a['Name'] }.sort == [
  #        "minecraft:generic.max_health", "minecraft:generic.movement_speed"
  #      ]
  #   - mobs unlikely will have enchanted items :)
  #   - player's team:    "name": "a828217146", "nameTagVisibilityRule": "ALWAYS",
  #     mob's team:       "name": "4qy2d0v641", "nameTagVisibilityRule": "NEVER",     
end

NONAGRESSIVE_FACTIONS = [
  "fkt_Kalhuiki Tri",
  "fkt_firemage ",
  "fkt_matcho ",
  "fkt_Krondor ",
  "fkt_BarbarianGua",
  "fkt_MageGuard ",
]

def is_mob? entity
  return false unless entity
  return false if ['minecraft:armor_stand'].include?(entity['id'])
  return false if entity.dig('nbt', 'Fuse') == 30 # some "creeper"-like protection aura
  return false if NONAGRESSIVE_FACTIONS.include?(entity['scoreboardTeam'])

  case entity['id']
  when "minecraft:wolf", "minecraft:zombie_horse"
    return true
  when "minecraft:villager"
    return entity['name'] =~ /(Green|Blue|Purple|Gold) Jerry/ # special Jerries when Mayor is a Jerry
  when "minecraft:bat"
    # XXX
    return entity.dig("nbt", "BatFlags") != 0
  end

  return false if entity['name'] == "Jerry" # Jerry @ home isle

  # "[Lv51] zed_0xff's Armadillo"
  return false if entity['name'].count("'") == 1 && entity['name'].count('❤') == 0
  # "Highmeon's AgentK 15M❤"
  return false if entity['name'].count("'") == 1 && !entity['name'].start_with?('[')

  # my Armadillo, maybe buggy
  return false if entity['name'] == "Zombie" && 
    (eff=entity.dig('nbt', 'ActiveEffects')) &&
     eff.size == 1 &&
     eff[0]['Id'] == 14

  # some 'pets' also have fkt_ team set
  return true if entity['scoreboardTeam'].to_s.start_with?("fkt_")

  Array(entity.dig('nbt', 'Attributes')).map{ |a| a['Name'] }.sort == [
    "minecraft:generic.max_health", "minecraft:generic.movement_speed"
  ]
end

def getMobs(
  radius: ENTITY_REACHABLE_DISTANCE,
  radiusY: nil,
  reachable: false,
  extra_commands: [],
  debug: false,
  classes: nil
)
  radiusY ||= ENTITY_REACHABLE_DISTANCE
  classes ||= %w'MobEntity OtherClientPlayerEntity'

  script = [
    { command: "status", intArg: MC.last_tick }, # will wait for next tick!
  ] +
  classes.map do |klass|
    { command: "entities",
      stringArg: klass,
      expand: { x: radius, y: radiusY, z: radius },
    }
  end + extra_commands

  r = MC.run_script! script

#  if debug && (r['mobs'].any? || r['players'].any?)
#    puts "[d] getMobs: #{r['mobs'].size} mobs, #{r['players'].size} players"
#  end

#  r['entities'] = (r['mobs'] + r['players']).find_all{ |p| is_mob?(p) }
  case reachable
  when true
    r['entities'].delete_if { |mob|
      distance(mob['boundingCenter']) > ENTITY_REACHABLE_DISTANCE ||
        distance(mob['eyePos']) > ENTITY_REACHABLE_DISTANCE
    }
  when :loose
    r['entities'].delete_if { |mob|
      distance(mob['boundingCenter']) > ENTITY_REACHABLE_DISTANCE && # <<< difference
        distance(mob['eyePos']) > ENTITY_REACHABLE_DISTANCE
    }
  end
  #r['entities'] += r['bats']
  r
rescue Errno::ECONNREFUSED, OpenURI::HTTPError, EOFError => e
  puts "[!] #{e}".red
  sleep 1
  retry
end

def reachable_block? x
  pos = 
    case x
    when Pos
      x
    when Array
      Pos[*x]
    when Hash
      if x.key?('pos')
        Pos[x['pos']]
      end
    else
      raise
    end
  distance(pos) < BLOCK_REACHABLE_DISTANCE
end

def reachable_entity? x
  pos = 
    case x
    when Pos
      x
    when Array
      Pos[*x]
    when Hash
      if x.key?('eyePos')
        Pos[x['eyePos']]
      end
    else
      raise
    end
  distance(pos) < ENTITY_REACHABLE_DISTANCE
end

def open_screen title, msg: title, command: nil, delay: 0.2
  unless is_current_screen?(title)
    chat command
    MC.invalidate_cache!
    wait_for_screen title, msg: msg
    sleep delay
    MC.invalidate_cache!
  end
  if block_given?
    yield MC.screen 
  else
    MC.screen
  end
end

$lastmove = Time.now - 1000
$lastmove_key = 'a'

def move_a_bit ratio = 20
  # it's easier to keep fishhook from stucking in ice if standing still
  return if MC.current_zone == "Jerry's Workshop"

  if rand(ratio) == 0
    return if Time.now - $lastmove < 10
    dir = ($lastmove_key == :left) ? :right : :left
    MC.travel! dir, amount: 0.1
    $lastmove = Time.now
    $lastmove_key = dir
  end
end

def suppress_button_release! value=true
  script = [
    { command: "suppressButtonRelease", boolArg: value, intArg: 0 }
  ]
  Net::HTTP.post(ACTION_URI, script.to_json).body
end

def max_hp mob
  r = mob.dig('nbt', 'Attributes').find{ |a| a['Name'] == 'minecraft:generic.max_health' }['Base']
  r = 2000000000 if r && r > 2000000000
  r
rescue
  0
end

def hp mob
  mob && mob.dig('nbt', 'Health').to_f
end

def format_time seconds
  seconds = seconds.to_i

  case seconds
  when 0..60
    "%ds" % seconds
  when 60..300
    "%dm %02ds" % [seconds/60, seconds%60]
  when 300..3600
    "%dm" % [seconds/60]
  when 3600..86400
    "%.1fh" % (seconds/3600.0).round(1)
  else
    "%.1fd" % (seconds/86400.0).round(1)
  end
end

def format_number value
  case value.abs
  when 0..9999
    value.round.to_s
  when 10000..999999
    (value/1000.0).round.to_s + "k"
  else
    (value/1000000.0).round(1).to_s + "M"
  end
end

def warp_random_hub
  MC.chat! "/warp hub"
  sleep 1
#  wait_for { MC.current_map == 'Hub' }
#  sleep 1
  MC.chat! "#goto -10 70 -69"
  sleep 1
  MC.chat! "#stop"
  MC.interact_entity! network_id: 260
  wait_for { MC.screen }
  MC.screen.click_on /Random Hub/
  prev_server = MC.current_server
  wait_for { MC.current_server != prev_server }
  sleep 4
end

def stash! x
  return unless MC.player.has?(x)
  screen = open_screen(/Ender Chest/, command: "/ec")
  screen.player_slots.each do |slot|
    slot.quick_move! if slot.stack&.is_a?(x)
  end
  @stashed = true
rescue
  puts "[?] stash failed: #{$!}".red
ensure
  MC.close_screen!
end

def unstash! x
  return if MC.player.has?(x)
  return if @stashed == false
  screen = open_screen(/Ender Chest/, command: "/ec")
  was = false
  screen.nonplayer_slots.each do |slot|
    if slot.stack&.is_a?(x)
      slot.quick_move!
      was = true
    end
  end
  @stashed = was
rescue
  puts "[?] unstash failed: #{$!}".red
ensure
  MC.close_screen!
end
