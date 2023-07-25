#!/usr/bin/env ruby
# frozen_string_literal: true
require 'yaml'
require_relative 'lib/skytime'
require_relative 'autoattack'
require_relative 'lib/brain/rule'
require_relative 'lib/auto_jump'
require_relative 'lib/fandom'
require_relative 'total_inventory'
require_relative 'enchant'

%w'helper tracker'.each do |t|
  Dir[File.join(File.dirname(__FILE__), "lib", "#{t}s", "*_#{t}.rb")].each do |fname|
    require_relative fname
  end
end

STDOUT.sync = true

MC.exit_on_esc = false

class Brain
  ATTACK_PROB = 0.9 + rand()/10
  INERTIA = 10
  CONFIG_FNAME = "config.yml"
  TICKS_PER_SEC = MC::TICKS_PER_SEC

  AUTOATTACK_MOBS = [
    "minecraft:blaze",
    "minecraft:enderman",
    "minecraft:endermite",
    "minecraft:iron_golem",
    "minecraft:player",
    "minecraft:silverfish",
    "minecraft:skeleton",
    "minecraft:slime",
    "minecraft:snow_golem",
    "minecraft:cave_spider",
    "minecraft:spider",
    "minecraft:squid",
    "minecraft:witch",      # XXX TODO: NPC witch
    "minecraft:wither_skeleton",
    "minecraft:wolf",
    "minecraft:zombie",
    "minecraft:zombie_horse",
    "minecraft:zombie_villager",
    "minecraft:zombified_piglin",

    "minecraft:mooshroom",
    "minecraft:rabbit",
    "minecraft:chicken",
    "minecraft:cow",
    "minecraft:pig",
    "minecraft:sheep",
  ]

  attr_reader :current_tick, :debug, :sms_queue

  def initialize argv = []
    @ticks = Hash.new(0)
    @blind_attacks = 0
    @seen_mobs = {}
    @release_suppressed = false
    @keyDown = nil
    @rules = read_rules
    @trackers = []
    @nreqs = 0
    @start_time = nil
    @hud = nil
    @screen_helpers = Hash[ BaseHelper.subclasses.map { |klass| [klass::SCREEN_TITLE, klass.new] }]
    puts "[.] #{@screen_helpers.size} helpers registered"
    @total_inventory = TotalInventory.new(quiet: true)
    @player = nil
    @afk_ticks = nil
    @debug = argv.count('-d')
    @debug = false if @debug == 0
    MC.debug = @debug
    @sms_queue = []

    MC.before_send do |script|
      if @start_time && @nreqs > 0
        prefix = "%d RPS" % (@nreqs/(Time.now-@start_time))
        suffix = ""
        suffix = ", %s AFK" % format_time(afk_seconds) if afk_seconds > 1
        speed = (player&.dig('nbt','abilities','walkSpeed') * 1000).round
        script.prepend(*[
          { command: "setTeamPrefix", stringArg: "team_1", stringArg2: prefix },
          { command: "setTeamSuffix", stringArg: "team_1", stringArg2: suffix },
          { command: "setTeamPrefix", stringArg: "team_2", stringArg2: "Speed: " },
          { command: "setTeamSuffix", stringArg: "team_2", stringArg2: speed },
        ])
      end
    end
  end

  def player
    @player ||= MC.player
  end

  def shortnum x
    x = x.to_i
    case x
    when 0..999
      x
    when 1000..9999
      (x/1000.0).round(1).to_s + "k"
    else
      "%dk" % (x/10000)
    end
  end

  def hold_left! ticks: nil
    ticks ||= INERTIA
    release! if @keyDown && @keyDown != 'key.mouse.left'
    @keyDown = 'key.mouse.left'
    press_key @keyDown
    @ticks[:hold_until] = MC.tick + ticks
  end

  def hold_right! ticks: nil
    ticks ||= INERTIA
    release! if @keyDown && @keyDown != 'key.mouse.right'
    @keyDown = 'key.mouse.right'
    press_key @keyDown
    @ticks[:hold_until] = MC.tick + ticks
  end

  def release!
    if @keyDown
      release_key @keyDown
      @keyDown = nil
    end
  end

  def read_rules
    @config_mtime = File.mtime(CONFIG_FNAME)
    rules = {}
    config = YAML::load_file( CONFIG_FNAME)
    config["rules"].each do |rulename, rule|
      rule['blocks'].each do |block|
        rules["minecraft:#{block}"] ||= []
        rules["minecraft:#{block}"] << Rule.new(rule, name: rulename, brain: self)
      end
    end
    puts "[.] got #{rules.size} rules from #{CONFIG_FNAME}"
    rules
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
  def smart_attack! mob
    return if MC.current_map == "Garden"
    if @next_attack_delay
      return if (MC.tick - @ticks[:attack]) < @next_attack_delay
    end
    @next_attack_delay = distributed_random(ATTACK_DISTRIBUTIONS)

    # TODO: select tool

    blind = mob.nil?
    if blind
      if @blind_attacks <=  0
        puts "[?] blind attacking with zero counter".yellow
        return
      end
      @blind_attacks -= 1
      @ticks[:attack] = MC.tick
      MC.attack!
    elsif rand() < ATTACK_PROB
      @blind_attacks = rand(3)
      @ticks[:attack] = MC.tick
      #MC.attack!
      MC.attack_entity! uuid: mob['uuid']
    else
      # skip tick
      @ticks[:attack] = MC.tick
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

  def process_commands
    commands = @status['commands']
    return unless commands

    # don't process pre-start commands
    @ticks[:command] = @start_tick if @ticks[:command] == 0

    commands.each do |tick, cmd|
      tick = tick.to_i
      next if tick <= @ticks[:command]

      case cmd
      when 'status'
        puts self.pretty_inspect
      when 'enchant', 'e'
        enchant_inventory!
      end

      @ticks[:command] = tick
    end
  end

  def should_attack? mob, mleft
    return true if mob['id'] == 'minecraft:villager' && mob['name'] =~ /(Green|Blue|Purple|Gold) Jerry/

    seen_this_mob_before = @seen_mobs.key?(mob['uuid'])
    (mleft['state'] == 0 && mleft['age'] < 7) ||
      (seen_this_mob_before && hp(mob) > 0) ||
      (mob['outlineColor'].to_i == MC::API::RED && hp(mob) > 0) ||
      (AUTOATTACK_MOBS.include?(mob['id']))
  end

  ETA_SUFFICES = {
    's' => 1,
    'm' => 60,
    'h' => 3600,
    'd' => 3600*24,
  }

  # and colorize line :]
  def parse_eta eta, l
    r = 0
    case eta.gsub(/§./,'')
    when 'Ready'
      l.insert(0, "§a") # green
      return 0
    when /\A\d+:\d+\Z/
      l.insert(0, "§6") # gold
      a = eta.split(":").map(&:to_i)
      return a[0]*60 + a[1]
    when /\A\d+:\d+:\d+\Z/
      l.insert(0, "§6") # gold
      a = eta.split(":").map(&:to_i)
      return a[0]*3600 + a[1]*60 + a[2]
    when /\A(\d+) days/i
      r = $1.to_i*3600*24
    when /\A(\d+) hours/i
      r = $1.to_i*3600
    when /\A(\d+) minutes/i
      r = $1.to_i*60
    else
      eta.split.each do |el|
        r += el.to_i * ETA_SUFFICES[el[-1]]
      end
    end

    if r < 3600
      l.insert(0, "§a") # green
    elsif r > 3600*12
      l.insert(0, "§8") # gray
    end
    r
  rescue
    puts "[d] eta: #{eta.inspect}, l: #{l.inspect}"
    raise
  end

  def get_battery
    return @battery_cache if @current_tick - @ticks[:battery] < TICKS_PER_SEC*60
    @ticks[:battery] = @current_tick
    @battery_cache =
      if `pmset -g batt`[/discharging; 0:(\d+) remaining/]
        ansi2mc("Battery: #{$1}:00".red)
      else
        nil
      end
  rescue
    puts "[!] get_battery: #{$!}".red
    return nil
  end

  def update_timers
    return if @current_tick - @ticks[:timers_hud] < 50
    @ticks[:timers_hud] = @current_tick
    lines = []
    return unless (plist = @status['playerList'])

    if (pet_sitter = plist[62])
      # "Pet Sitter: 2d 1h 17m 50s"
      pet_sitter.strip!
      lines << pet_sitter unless pet_sitter.end_with?('N/A')
    end

    if (next_visitor = plist[45]) && next_visitor['Next Visitor:'] && !next_visitor[/Full|Not Un/]
      lines << next_visitor.strip
    end

#    if (srvc=@status.dig('sidebar', 1)) && srvc.start_with?('Server closing')
#    end

    if (footer=@status['playerListFooter'])
      a = footer.split('§s').map(&:strip)
      if (upgrades = a.find{ |p| p =~ /\AUpgrades/ })
        lines.append *upgrades.sub("Upgrades","").strip.split("\n")
      end
      if (effects = a.find{ |p| p =~ /\AActive Effects/ })
        lines.append *effects.scan(/^.+\d$/)
      end
    end
    
    if plist[73].to_s['Starts In']
      event = plist[72,2].join.
        sub(/^Event: /,'').
        sub(" Starts In",'')
      lines << event unless event['Election Booth Opens']
    elsif plist[74].to_s['Starts In']
      event = plist[73,2].join.
        sub(/^Event: /,'').
        sub(" Starts In",'')
      lines << event unless event['Election Booth Opens']
    end

    lines << get_battery

    lines.compact!
    lines.delete("")
    lines.map! { |l| a = l.sub(/ [IV]+ /, ": ").split(": ", 2); a[1] = parse_eta(a[1], a[0]); a }

    # Jerry's workshop
    now = Skytime.now
    case now.month
    when 11
      lines << ["JWorkshop opens", Skytime.new(now.year, 12) - now]
    when 12
      lines << ["JWorkshop closes", Skytime.new(now.year+1, 1) - now]
    end

    if (jline = lines.find { |l| l[0]["Season of Jerry"] })
      dt_start = jline[1] - 23*20*60
      if dt_start > 0
        lines.delete(jline)
      else
        jline[0] = "Defend JWorkshop"

        dt_end = jline[1] + 8*20*60
        lines << [ansi2mc("JWorkshop closes".yellowish), dt_end]
      end
    end

    # farming
    calendar = Fandom.farming_calendar
    if (fline = lines.find { |l| l[0]["Jacob's Farming"] })
      # event is currently active
      if (c=calendar[now.day_no])
        fline[0] = "§6"+c["crops"].map{|x| x[0,5]}.join(", ")
      end
    else
      next_fday = 3*((now.day_no+3)/3)-1
      if (f=calendar[next_fday])
        msg = f["crops"].map{|x| x[0,5]}.join(", ")
          .sub("Carro", "§6Carro§r")
          .sub("Nethe", "Wart")
        lines << [msg, Skytime.new(now.year, f["month"], f["day"])-now]
      end
    end

    lines.sort_by!(&:last)
    lines.reverse!
    @hud = lines.map { |l,eta| l + ": " + format_time(eta) }.join("\n")

#    @hud = lines.
#      map{ |l| l.sub(/ [IV]+ /, ": ").split(": ", 2) }.
#      sort_by { |l,eta| -parse_eta(eta, l) }.
#      map{ |l,eta| l + ": " + eta.split[0,2].join(' ') }.
#      join("\n")
  end

  def track
    return if @current_tick - @ticks[:track] < 20
    @ticks[:track] = @current_tick
    @trackers.each do |t|
      r = t.track!(@status)
      if r && r.is_a?(Array) && r.any?
        @sms_queue.append(*r)
      end
    end
  end

  def autofish
    return if player['fishHook']
    return unless @status.dig('raytrace', 'block', 'id') == 'minecraft:water'
    return unless player.has?(:fishing_rod)
    return if afk_ticks < 50
    return if @current_tick - @ticks[:autofish] < 30

    @ticks[:autofish] = @current_tick
    select_tool :fishing_rod
    right_click!
  end

  def afk_seconds
    afk_ticks / TICKS_PER_SEC
  end

  def afk_ticks
    @afk_ticks ||= 
      begin
        r = 999999999999
        @status['input']&.each do |k,v|
          if v['state'] == 1
            return 0
          end
          r = [v['age'], r].min
        end
        r
      end
  end

# bad:
# [21:43:14] [Netty Client IO #1/INFO]: SEND ClickSlotC2SPacket{ syncId=0, revision=1, slot=9, button=7, actionType=SWAP, stack=net/minecraft/item/ItemStack{ count=1, bobbingAnimationTime=0, item=null, nbt=null, empty=true, holder=null, destroyChecker=null, placeChecker=null, baritoneHash=-1, fabric_damagingEntity=null, fabric_breakCallback=null }, modifiedStacks={9=>1 air, 43=>16 cocoa_beans} }

# good:
# [21:44:24] [Netty Client IO #1/INFO]: SEND ClickSlotC2SPacket{ syncId=0, revision=1, slot=9, button=7, actionType=SWAP, stack=net/minecraft/item/ItemStack{ count=1, bobbingAnimationTime=0, item=null, nbt=null, empty=true, holder=null, destroyChecker=null, placeChecker=null, baritoneHash=-1, fabric_damagingEntity=null, fabric_breakCallback=null }, modifiedStacks={9=>1 air, 43=>16 cocoa_beans} }


  # skyblock has some sort of autorestock prevention - connection immediately drops with 'bad client inventory move'
  # same for tweakeroo mod
  def restock
    return if (current_tick - @ticks[:restock]) < 100
    return if @status['screen']
    return unless (cur = player.current_stack)
    prev = @prev_stack

    if prev && cur.skyblock_id == prev.skyblock_id && cur.count < prev.count
      t = Time.now.to_i
      if t == @prev_dec_time
        @ndec += 1
#        puts "[d] #{Time.now.to_i}: #{cur.display_name}: #{prev.count} -> #{cur.count} [#@ndec]"
        if @ndec >= 3
          # check if we already have next stack in hotbar
          # try to restock any empty hotbar slot, works well with Rule's tool selection
          if (next_stack = player.inventory.find { |x| x.skyblock_id == cur.skyblock_id && x.slot_id != cur.slot_id })
            if next_stack.slot_id in Player::HOTBAR_SLOTS
              # we're good
            elsif (free_slot = player.hotbar.find(&:empty?))
              # move
              @ticks[:restock] = current_tick
              puts "[d] moving.."
              MC.click_inventory_slot! next_stack.slot_id, action_type: "QUICK_MOVE"
              # server will not drop connection it sees CloseHandledScreenC2SPacket, LOL :D
              script = [ { command: "closeHandledScreen" } ]
              MC.run_script! script
            end
          end
        end
      else
        @ndec = 0
      end
      @prev_dec_time = t
    end
    @prev_stack = cur

    return

    if player.current_tool.nil?
      if @prev_stack && ((current_tick - @ticks[:restock]) < 10) && (x=player.has?(@prev_stack.skyblock_id))
        if (current_tick - @ticks[:last_swap]) > 20
          puts "[.] restocking #{@prev_stack.display_name}"
          MC.script do
            select_slot! 7
            click_inventory_slot! x.slot_id, action_type: "SWAP", button: 7 #player.inventory.selected_slot
          end
#          MC.script do
#            click_inventory_slot! x.slot_id
#            click_inventory_slot! player.inventory.selected_slot
#          end
          @ticks[:last_swap] = current_tick
        end
      else
        @prev_stack = nil
      end
    elsif player.current_tool.count > 1
      @prev_stack = player.current_tool
      @ticks[:restock] = current_tick
    end
  end

  def bootstrap!
    MC.script do
      status!
#      register_command! "status"
#      register_command! "e"
#      register_command! "enchant"
      say! "[:] brain connected"
      clear_spam_filters!
      add_spam_filter! "died to a trap"
      add_spam_filter! "Kill Combo has expired"
      add_spam_filter! "Whow! Slow down there"
      add_spam_filter! " was killed by "
      add_spam_filter! "joined the lobby!"
      add_spam_filter! "if you're dead, how are you reading this"
      add_spam_filter! "learn to play the game"
      add_spam_filter! "(?i)(lowballing|easy flip|: selling)"
      add_spam_filter! "Blacklisted modifications are a bannable offense"
      add_spam_filter! "LOOT SHARE You received loot"
      add_spam_filter! "Powder amount is back to normal,"
      add_spam_filter! "Staff have banned an additional"
      add_spam_filter! "The sound of pickaxes clashing against the rock"
      add_spam_filter! "The wind has changed direction"
      add_spam_filter! "WATCHDOG ANNOUNCEMENT"
      add_spam_filter! "Watchdog has banned"
      add_spam_filter! "You are playing on profile:"
      add_spam_filter! "You found an? (Sponge|[a-zA-Z]+ Bait|Golden Apple|Sea Lantern|Prismarine|Music Disc|Enchanted)"
      add_spam_filter! "You laid an egg"
      add_spam_filter! "You received loot for assisting"
      add_spam_filter! "\\[NPC\\] .{0,2}Don Expresso.{0,2}:"
      add_spam_filter! "fell into the void"
      add_spam_filter! "fell to their death"
      add_spam_filter! "got you double drops!"
      add_spam_filter! "mounted a Snow Cannon"
      add_spam_filter! "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
    end
  end

  def mob2tool mob
    case mob['id']
    when 'minecraft:spider', 'minecraft:cave_spider'
      return /LIVID_DAGGER|_FANG/
    when 'minecraft:enderman'
      return /LIVID_DAGGER|_KATANA|VOID_SWORD/
    end

    case mob['name']
    when /Ice Walker/
      /LIVID_DAGGER|PICKAXE/
    when /Silverfish/
      /LIVID_DAGGER|CUTLASS|SWORD|CLEAVER|RABBIT_AXE|RAIDER_AXE|_FANG/
    else
      /LIVID_DAGGER|RAIDER_AXE|VOID_SWORD/
    end
  end

  def think!
    prevline = nil
    @keyDown = false
    @afk_ticks = nil
    prevexp = nil

    @status = bootstrap!
    @nreqs += 1
    @start_tick = @status['tick']
    @start_time = Time.now

    @trackers = [
      EggTracker.new,
      ToolAttributeTracker.new,
      ToolCounterTracker.new,
      SkillTracker.new,
    ]

    prev_tick = @status['tick']
    prev_player = player
    procs = []

    loop do
      hud = @hud
      @player = nil
      @afk_ticks = nil
      @sms_queue.uniq!
      smsq = @sms_queue
      printf("[d] [%d] %.3fs thinking\n", @current_tick, Time.now-@t_start_processing) if debug && @t_start_processing
      @t_start_script = Time.now
      @status = MC.script do |x|
        procs.each do |p|
          p.call(x)
        end
        if smsq.any?
          say! smsq.sort.join(", "), quiet: true
          smsq.clear
        end
        add_hud_text! hud, x: -2, y: 2, ttl: 300
        status!
        raytrace!(range: ENTITY_REACHABLE_DISTANCE+3, liquids: false)
        raytrace!(range: BLOCK_REACHABLE_DISTANCE, liquids: false, entities: false, result_key: "raytrace_block")
        blocks!(offset: nil, expand: {x: 1, y: 1, z: 1}, string_arg: "looking_at", result_key: "blocks_around_looking_at")
        entities!(radius: ENTITY_REACHABLE_DISTANCE, type: "ArmorStandEntity")
      end
      @current_tick = @status['tick']
      printf("[d] [%d] %.3fs script\n", @current_tick, Time.now-@t_start_script) if debug
      @t_start_processing = Time.now
      procs.clear
      raytrace = @status['raytrace']

#      dtick = @current_tick-prev_tick
#      puts "[d] tick: #{@current_tick}, dtick=#{dtick}, #{dtick/(Time.now-@t0)} TPS" if debug && dtick > 1
#      @t0 = Time.now

      if @current_tick < prev_tick || prev_player.data_dir != player.data_dir
        # client restart / profile change
        return true
      end
      prev_tick = @current_tick
      prev_player = player

      @nreqs += 1
      if @status
        case @status.dig('sidebar', 0)
        when /^SKYBLOCK/
          # oky
        when 'HYPIXEL', 'PROTOTYPE', 'HOUSING'
          if @ticks[:skyblock] == 0 || (MC.tick - @ticks[:skyblock]) > 30*TICKS_PER_SEC
            @ticks[:skyblock] = MC.tick
            chat "/skyblock"
          end
          sleep 2
          next
        else
          #if @status.dig('hud', 'title') == "You are AFK"
          if (pos=@status.dig('player', 'pos')) && pos.values.map(&:to_i) == [-23, 31, 21]
            if @ticks[:limbo] == 0 || (MC.tick - @ticks[:limbo]) > 30*TICKS_PER_SEC
              @ticks[:limbo] = MC.tick
              chat "/lobby"
            end
          end
          sleep 2
          next
        end
      else
        sleep 1
        next
      end

      AutoHeal.heal! player
      #AutoJump.jump! player if MC.current_zone == "Jungle Temple"
      update_timers
      process_commands

      next if player.inventory[0].is_a?("HAUNT_ABILITY")

      autorun
      restock

      # magick stick :D
      if (@current_tick - @ticks[:hide]) > 2
        if player.current_tool&.is_a?("STICK")
          if (uuid = @status.dig('player', 'looking_at', 'entity', 'uuid'))
            MC.hide_entity!(uuid) if @status.dig('input', 'key.mouse.left', 'state') == 1
          elsif (pos = @status.dig('player', 'looking_at', 'block', 'pos'))
            MC.hide_block!(pos) if @status.dig('input', 'key.mouse.right', 'state') == 1
          elsif (pos = @status.dig('raytrace', 'block', 'pos'))
            MC.hide_block!(pos) if @status.dig('input', 'key.mouse.right', 'state') == 1
          end
        elsif @status.dig('input', 'key.mouse.right', 'state') == 1
          if (block = @status.dig('player', 'looking_at', 'block')) && block['id'] == 'minecraft:cobweb'
            # cheating...
            MC.hide_block!(block['pos'])
          end
        end
      end

      screen = nil
      if @status['screen']
        screen = Screen.new(@status['screen'])
        @screen_helpers.each do |k, helper|
          if screen.title[k]
            helper.handle(screen)
          end
        end
      else
        track
      end

      # autoshoot
      if player.current_tool&.is_a?(/DUNGEON_STONE|INK_WAND/)
        MC.script do
          interact_item!
          select_slot! 0
        end
      end

      lshift = status.dig('input', 'key.keyboard.left.shift', 'state')
      mright = status.dig('input', 'key.mouse.right', 'state')

      if (mright != 1) && (mob = @status.dig('raytrace', 'entity')) && is_mob?(mob)
        line = shortstatus(mob)
        if line != prevline
          puts line unless prevline&.start_with?(line)
          prevline = line
        end

        # suppress tool change if shift is held
        while (lshift == 0) && (current_tick - @ticks[:change_tool]) > 5
          break if player.current_tool&.is_a?(/SHORTBOW/) && status.dig('input', 'key.mouse.right', 'age') < 50

          if (new_tool = mob2tool(mob))
            if select_tool(new_tool)
              @ticks[:change_tool] = current_tick
            elsif select_tool(/KNIFE|SWORD|CLEAVER|BLADE/)
              @ticks[:change_tool] = current_tick
            end
          end
          break
        end

        mleft = @status.dig('input', 'key.mouse.left')
        if mob.dig('nbt', 'Invisible') == 1
          MC.say! "[!] stop attacking invisible mob!"
          @blind_attacks = 0
        elsif should_attack?(mob, mleft)
          @seen_mobs[mob['uuid']] = mob
          @ticks[:attack] = MC.tick - mleft['age']
          MC.outline_entity! mob['uuid']
          smart_attack! mob
        elsif @blind_attacks > 0
          @seen_mobs[mob['uuid']] = mob
          smart_attack! nil
        end
      elsif (MC.tick - @ticks[:attack]) < 7 && (@blind_attacks > 0)
        # continue attacking to simulate real player behavior
        smart_attack! nil
        next
      end

      #puts "[d] [#{MC.tick}]" if debug
      # suppress rule processing if shift is held
      if lshift == 0 && player.current_tool&.skyblock_id != "DWARVEN_METAL_DETECTOR"
        t0 = Time.now
        #block = @status.dig('raytrace_block', 'block')
        block = @status.dig('player', 'looking_at', 'block')
#        if block && block['id'] == "minecraft:air" && raytrace && raytrace['distance'] < BLOCK_REACHABLE_DISTANCE
#          block = raytrace['block']
#        end
        printf("[d] [%d] block: %s\n", @current_tick, block.inspect) if debug
        if block && (rules = @rules[block['id']])
          rules.each do |rule|
            r = rule.run!(block, @status)
            puts "[*] [#{@current_tick}] #{rule}" if debug && r
            procs << r if r.is_a?(Proc)
          end
          if debug
            dt = Time.now-t0
            printf("[d] [%d] %.3f rules processing\n", @current_tick, dt) if dt > 0.001
          end
        end
      end

      #autofish
      @total_inventory.tick screen: screen, player: player

      exp = [player.experienceLevel, player.experienceProgress]
      if exp != prevexp && prevexp
        delta = exp_diff(prevexp, exp)
        if delta.abs >= 100
          if delta < 0
            @sms_queue << ("%d exp" % delta)
          else
            @sms_queue << ("+%d exp" % delta)
          end
        end
      end
      prevexp = exp

      if player.inventory[39]&.skyblock_id == "CHICKEN_HEAD" && 
          player['pose'] == 'STANDING' &&
          player['speed'] == 0

        if !@next_crouch || (Time.now > @next_crouch)
          puts "[d] #{Time.now} laying egg.."
          press_key 'key.keyboard.left.control'
          sleep(0.1 + rand()/10)
          release_key 'key.keyboard.left.control'
          @next_crouch = Time.now + 20 + rand(10)
        end
      end

      shoot_cannon!
      open_gifts!

      if @release_suppressed && (MC.tick - @ticks[:mine]) > INERTIA
        puts "[d] releasing suppress"
        @release_suppressed = false
        suppress_button_release! false
        #release_key 'key.mouse.left'
      end
      if @keyDown && (MC.tick >= @ticks[:hold_until])
        release!
      end
      #sleep(1.0/TICKS_PER_SEC)
      sleep 0.005
    end
  rescue Interrupt
    exit
  rescue => e
    puts "[!] #{e.class}: #{e}".red
    e.backtrace.each do |line|
      puts "  #{line}"
    end
  end
end

def shoot_cannon!
  if status.dig('sidebar', 7) =~ /^Wave /
    case status['overlay']
    when /§e§lRIGHT-CLICK §fto §6§lFIRE/
      press_key 'key.mouse.right', 0
      sleep 0.05
    when /§7to §8§lFIRE/
      release_key 'key.mouse.right'
    end
  end
end

def open_gifts!
  @status['entities'].each do |e|
    if e['name'] == "CLICK TO OPEN"
      MC.interact_entity! uuid: e['uuid']
    end
  end
end

if $0 == __FILE__
  loop do
    r = Brain.new(ARGV).think!
    unless r
      MC.say! "[!!!] brain disconnected!".red
      sleep 5
    end
  end
end
