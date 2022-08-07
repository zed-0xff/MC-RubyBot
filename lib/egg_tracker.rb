# frozen_string_literal: true
require 'yaml'

class EggTracker

  RANGE = 20
  TRACK_INTERVAL = 0.5

  TRACKABLES = {
    Egg: {
      type: "ArmorStandEntity",
      detect: Proc.new{ |e|
        e.dig('nbt', 'ArmorItems', 3, 'tag' ,'SkullOwner', 'Id') == 
          [ 1470417116, -1685177023, -2133154296, -1877319353 ] 
      },
      outline: :nearest,
      color: 0x00FFFFFF, # cyan
      track_seen: true,
    },
    Gift: {
      type: "ArmorStandEntity",
      detect: Proc.new{ |e|
        e.dig('nbt', 'ArmorItems', 3, 'tag' ,'SkullOwner', 'Id') == 
          [ 1999816164, 402668432, -1492159875, 694756683 ]
      },
      outline: :all,
      color: 0xFFFFFFFF,
      track_seen: true,
    },
    Rat: {
      type: "ArmorStandEntity",
      detect: Proc.new{ |e| e["name"] =~ /^\[Lv1\] Rat \d+\/5000❤$/ },
      outline: :all,
      color: 0xFEBE00FF, # yellowish
      track_seen: false,
    },
    Ticket: {
      type: "ItemEntity",
      detect: Proc.new{ |e| e.dig('nbt', 'Item', 'id') == "minecraft:name_tag" },
      outline: :all,
      color: 0xFFFFFFFF,
      track_seen: false,
    },
  }.freeze

  def initialize player_uuid
     @player_uuid = player_uuid
     @data = load_data
     @last_track = Time.now - 1000
     @outlined = nil
  end

  def load_data
    if File.exist?(data_fname)
      YAML::load_file(data_fname)
    else
      {}
    end
  end

  def save_data
    File.write(data_fname, @data.to_yaml)
  end

  def data_fname
    return nil unless @player_uuid
    @data_fname ||=
      begin
        player_dir = File.join "data", @player_uuid
        Dir.mkdir(player_dir) unless Dir.exist?(player_dir)
        File.join player_dir, "egg_tracker.yml"
      end
  end

  def seen? e
    key = e['pos'].values.join(",")
    @data[key]
  end

  def trackable_type e
    SKULL_TRACKABLES.find{ |k,v| skull_id(e) == v }.first
  end

  def seen! e
    key = e['pos'].values.join(",")
    @data[key] = {
      "zone" => MC.current_zone,
      "type" => trackable_type(e),
    }
    save_data
  end

  def is_trackable? e
    if (skull_id = skull_id(e))
      return true if skull_id == SKULL_TRACKABLES["Egg"]
      return true if skull_id == SKULL_TRACKABLES["Gift"] && MC.current_zone == "Jerry's Workshop"
    end
    return NAME_TRACKABLES.any?{ |re| e['name'] =~ re }
  end

  def skull_id e
    (head = e.dig('nbt', 'ArmorItems', 3, 'tag' ,'SkullOwner', 'Id')) &&
      (head['id'] == "minecraft:player_head") &&
      (head.dig('tag', 'SkullOwner', 'Id'))
  end

  def track!
    return if Time.now - @last_track < TRACK_INTERVAL
    return if MC.overlay["CHICKEN RACING"]
    @last_track = Time.now

    r = MC.script do
      get_entities type: "ArmorStandEntity", radius: RANGE, result_key: "armor_stands"
      get_entities type: "ItemEntity", radius: RANGE, result_key: "items"
    end

    # eggs, gifts, archeology
    eggs = r['armor_stands'].find_all do |e|
      (hp(e).to_i == 20) && is_trackable?(e) && !seen?(e)
    end

    tickets = r['items'].find_all do |i|
      # or display_name "Raffle Ticket"
      i.dig('nbt', 'Item', 'id') == "minecraft:name_tag"
    end

    unless (egg = eggs.sort_by{ |e| distance(r['player']['eyePos'], e['pos']) }.first)
      MC.outline_entity!(@outlined, false) if @outlined
      @outlined = nil
      return 
    end

    name = trackable_type(egg) + " #" + egg['uuid'][-6..-1]

    if MC.player.dig('looking_at', 'entity', 'uuid') == egg['uuid']
      msg = "Found #{name} !".green
      seen! egg
      MC.outline_entity! egg['uuid'], false
      @outlined = nil
    else
      msg = "%.2f to %s".gray % [distance(r['player']['eyePos'], egg['pos']), name]
      if @outlined != egg['uuid']
        MC.outline_entity!(@outlined, false) if @outlined
        MC.outline_entity! egg['uuid'], true
        @outlined = egg['uuid']
      end
    end

    say msg unless @prevmsg == msg
    @prevmsg = msg
  end
end
