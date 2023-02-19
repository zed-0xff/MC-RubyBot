#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'lib/common'

seen = {}

def cleanup e
  e = e.except(
    *%w'
    boundingBox
    boundingCenter
    pose
    pos
    eyePos
    horizontalFacing
    visibilityBoundingCenter
    yaw
    pitch
    '
  )
  e.delete('class') if e['classShort']
  e.delete_if{ |k,v| v.nil? || v == 0 || v == [] }
  e['nbt'].delete_if{ |k,v| v.nil? || v == 0 || v == [] }
  e['nbt'] = e['nbt'].except(
    *%w'
    HandItems
    Motion
    Health
    Brain
    Pos
    Pose
    Rotation
    Air
    foodSaturationLevel
    OnGround
    DataVersion
    foodLevel
    UUID
    '
  )
  if (inv=e['nbt']['Inventory'])
    e['nbt'].delete('Inventory') if inv.size > 2
  end
  e
end

loop do
  entities = MC.get_entities!(radius: 20)['entities']
  entities.each do |e|
    next if e['id'] == 'minecraft:fishing_bobber'
    next if e['id'] == 'minecraft:snowball'
    e = cleanup(e)

    uuid = e['uuid']
    next if seen[uuid]
    seen[uuid] = e

    printf "%6d  %-20s %s\n".green, e['network_id'], e['id'].sub('minecraft:',''), e['name']
    #pp e
    #puts
  end
  sleep 0.5
end
