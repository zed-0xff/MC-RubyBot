#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'lib/common'

hidden = {}

loop do
  r = MC.script do
    add_hud_text! "#{hidden.size} players hidden", x: 200, y: 1, key: "players_hidden", ttl: 400
    get_entities! type: "OtherClientPlayerEntity", radius: 40
  end
  uuids = []
  r['entities'].each do |e|
    uuid = e['uuid']
    next if hidden[uuid]

    color = :gray
    name = e.dig('name')
    if name[r.dig('player', 'name')]
      color = :red
    elsif is_player?(e)
      hidden[uuid] = true
      color = :green
      uuids << uuid
    end
    printf "[.] %-20s %s\n".send(color), e.dig('name'), e.dig('scoreboardTeam')
  end
  if uuids.any?
    MC.script do
      uuids.each do |uuid|
        hide_entity! uuid
      end
    end
  end
  sleep 2
end
