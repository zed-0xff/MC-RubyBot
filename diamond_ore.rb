#!/usr/bin/env ruby
require_relative 'lib/common'
require_relative 'enchant'

BLOCK_ID = "minecraft:diamond_block"

def enchant!
  begin
    #enchant_inventory!
    enchant_all! filter: 'MINING'
  rescue => e
    puts "[!] #{e}".red
    sleep 1
    return
  ensure
    MC.close_screen!
  end
  sleep 0.2
end

def gather_near
  r = MC.blocks!
  blocks = r['blocks']

  targets = blocks.
    find_all{ |b| b['id'] == BLOCK_ID }.
    sort_by{ |b| distance(b['pos']) }

  targets.each do |lp|
    r = MC.look_at_block! lp['pos']
    sleep 0.4
    enchant! if MC.player.inventory.full?
  end
  targets.size
end

def gather_far
  r = MC.blocks!(
    filter: BLOCK_ID,
    radius: 30,
    radiusY: 5
  )

  printf "[.] found %d blocks\n", r['blocks'].size
  r['blocks'].
    sort_by{ |b| distance(b['pos']) }.
    each do |b|
    MC.chat! "#goto #{b['pos'].values.join(' ')}"
    sleep 0.5
    if wait_for(max_wait: 5, raise: false) { MC.player.speed != 0 }
      sleep 5
      wait_for(max_wait: 60, raise: false) { MC.player.speed == 0 }
      break
    end
  end
end

MC.chat! "#stop"
MC.chat! "#set allowBreak true"

enchant! if MC.player.inventory.full?

loop do
  respect_player
  gather_near
  gather_far
  sleep 1
end
