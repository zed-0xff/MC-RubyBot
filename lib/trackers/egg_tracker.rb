# frozen_string_literal: true
require 'fileutils'
require 'yaml'
require 'set'

class EggTracker

  RANGE = 60
  TRACK_INTERVAL = 0.25

  RELICS = [
    [-217, 58, -304],
    [-206, 63, -301],
    [-384, 89, -225],
    [-178, 136,-297],
    [-188, 80, -346],
    [-147, 83, -335],
    [-303, 71, -318],
    [-300, 51, -254],
    [-275, 64, -272],
    [-272, 48, -291],
    [-348, 65, -202],
    [-284, 49, -234],
    [-328, 50, -237],
    [-274, 100,-178],
    [-311, 69, -251],
    [-354, 73, -285],
    [-236, 51, -239],
    [-296, 37, -270],
    [-317, 69, -273],
    [-183, 51, -252],
    [-254, 57, -279],
    [-342, 122,-253],
    [-300, 50, -218],
    [-313, 58, -250],
    [-372, 89, -242],
    [-225, 70, -316],
    [-342, 89, -221],
    [-355, 86, -213],
  ]

  TRACKABLES = {
    Egg: {
      class: "ArmorStandEntity",
      detect: Proc.new{ |e|
        e.dig('nbt', 'ArmorItems', 3, 'tag' ,'SkullOwner', 'Id') == 
          [ 1470417116, -1685177023, -2133154296, -1877319353 ] 
      },
      color: 0x00FFFFFF, # cyan
      static_coords: true,
      hide_seen: true,
    },
    Gift: {
      class: "ArmorStandEntity",
      detect: Proc.new{ |e|
        e.dig('nbt', 'ArmorItems', 3, 'tag' ,'SkullOwner', 'Id') == 
          [ 1999816164, 402668432, -1492159875, 694756683 ]
      },
      outline: :all,
      color: 0xFFFFFFFF,
      static_coords: true,
      hide_seen: true,
      yearly: true,
    },
    Rat: {
      class: "ZombieEntity",
      detect: Proc.new{ |e| e.dig("nbt", "IsBaby") == 1 && [5000, 10000].include?(max_hp(e)) },
      outline: :all,
      color: 0xFEBE00FF, # yellowish
    },
    Ticket: {
      class: "ItemEntity",
      detect: Proc.new{ |e| e.dig('nbt', 'Item', 'id') == "minecraft:name_tag" },
      outline: :all,
      color: 0xFFFFFFFF,
    },
    Pelts: {
      class: /(Horse|Cow|Sheep|Rabbit|Chicken|Horse)Entity/,
      detect: Proc.new{ |e| e['name'] =~ /trackable|dangered|detected|elusive/i },
      outline: :all,
      color: 0xFEBE00FF, # yellowish
    },
  }

  TRACKABLES.each do |type, tinfo|
    tinfo[:type] = type
  end

  TRACKABLES.freeze

  def initialize
    @data_dir = MC.player.data_dir
    @data = load_data
    @last_track = Time.now - 1000
    @outlineds = {}
    @cache = {}
    @tracked_uuids = Set.new
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
    @data_fname ||=
      begin
        FileUtils.mkdir_p(@data_dir) unless Dir.exist?(@data_dir)
        File.join @data_dir, "egg_tracker.yml"
      end
  end

  def seen? e, type
    key = e['pos'].values.join(",")
    r = @data.dig(type.to_s, key)
    if r && TRACKABLES[type][:yearly]
      r['year'] == Skytime.now.year
    else
      r
    end
  end

  def seen! e, type
    key = e['pos'].values.join(",")
    @data[type.to_s] ||= {}
    @data[type.to_s][key] = {
      "zone" => MC.current_zone,
      "time" => Time.now.to_i,
      "year" => Skytime.now.year,
    }
    save_data
  end

  # return: nil or Trackable
  def is_trackable? e
    TRACKABLES.each do |type, tinfo|
      case tinfo[:class]
      when Regexp
        next if tinfo[:class] !~ e['classShort']
      when String
        next if tinfo[:class] != e['classShort']
      else
        raise tinfo[:class].inspect
      end
      return tinfo if tinfo[:detect].call(e)
    end
    nil
  end

  def track! status
    return if Time.now - @last_track < TRACK_INTERVAL
    return if MC.overlay["CHICKEN RACING"]
    @last_track = Time.now

    r = MC.script do
      get_entities! type: "ArmorStandEntity", radius: RANGE
      get_entities! type: "ItemEntity", radius: RANGE
      get_entities! type: "ZombieEntity", radius: RANGE
      get_entities! type: "AnimalEntity", radius: RANGE
    end

    nearests = {}
    to_outline = {}

    r['entities'].each do |e|
      uuid = e['uuid']
      t = 
        if @cache.key?(uuid)
          @cache[uuid]
        else
          @cache[uuid] = is_trackable?(e)
        end
      next unless t

#      if t[:outline] == :nearest
#        nearests[t[:type]] ||= []
#        nearests[t[:type]] << e
#      else
        to_outline[uuid] ||= t[:color] unless e['outlineColor']
#      end

      if t[:hide_seen]
        if seen?(e, t[:type])
          to_outline[uuid] = 0
        elsif MC.player.dig('looking_at', 'entity', 'uuid') == e['uuid']
          seen!(e, t[:type])
          to_outline[uuid] = 0
        end
      end
    end

    if to_outline.any?
      MC.script do
        to_outline.each do |uuid, color|
          outline_entity! uuid, color
        end
      end
    end

#    nearests.each do |type, entities|
#      e = entities.sort_by{ |e| distance(r['player']['eyePos'], e['pos']) }.first
#      nearest_uuid = e['uuid']
#      name = "#{type} #" + nearest_uuid[-6..-1]
#
#      if MC.player.dig('looking_at', 'entity', 'uuid') == e['uuid']
#        msg = "Found #{name} !".green
#        seen! e
#        MC.outline_entity! e['uuid'], false
#        @outlineds[type] = nil
#      else
#        msg = "%.2f to %s".gray % [distance(r['player']['eyePos'], e['pos']), name]
#        if @outlineds[type] != nearest_uuid
#          outlineds = @outlineds
#          MC.script do
#            outline_entity!(outlineds[type], false) if outlineds[type]
#            outline_entity!(nearest_uuid, TRACKABLES[type][:color])
#          end
#          @outlineds[type] = nearest_uuid
#        end
#      end
#
#      MC.say! msg unless @prevmsg == msg
#      @prevmsg = msg
#    end
  end

  def inspect
    "#<EggTracker>"
  end
end
