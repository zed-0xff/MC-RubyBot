#!/usr/bin/env ruby
require_relative '../autoattack'

$stdout.sync = true

LOG_FNAME = "~/minecraft/logs/latest.log"

# level 1 slots:
#
#      04      round
#  12  13  14
#  21  22  23
#  30  31  32
#
#      49      timer

# level 2 slots:
#
#          04
#  11  12  13  14  15
#  20  21  22  23  24
#  29  30  31  32  33
#
#          49

FIRST_NOTE_SLOT = {
  'High'  => 12,
  'Grand' => 11,
}

MC.cache_ttl = 0.01

def get_sounds round, msg
  r = []
  t0 = Time.now
  File.open(File.expand_path(LOG_FNAME), "r") do |f|
    f.seek -1000, :END
    loop do
      if (line = f.gets)
        break if line[msg]
      end
      sleep 0.01
    end
    loop do
      line = f.gets
      if (Time.now - t0) > (round*3)
        puts "[?] failed to get sounds :("
        exit 1
      end
      if line.to_s =~ /sound: minecraft:block\.note_block\.pling,.*pitch:\s*(\d\.\d)/
        #puts "[d] #{line}"
        # 0.5 RED
        # 0.6 BLUE
        # 0.7 LIME
        # 0.8 YELLOW
        # 1.0 AQUA
        note = (($1.to_f*10).to_i - 5)
        note -= 1 if note == 5
        r << note
        printf " %d", note
        if r.size == round
          puts
          return r 
        end
      end
    end
  end
end

ROUND_SLOT_IDX = 4
MODE_SLOT_IDX = 49

def solve
  puts "[!] equip Guardian pet!"
  round = 1
  wait_for("Chronomatron screen", max_wait: nil) { MC.screen && MC.screen.title =~ /Chronomatron \(.+\)/ }
  loop do
    wait_for(max_wait: nil) { MC.screen && MC.screen.slots[ROUND_SLOT_IDX].stack.is_a?(:bookshelf) }
    bookshelf = MC.screen.slots[ROUND_SLOT_IDX].stack
    mode_stack = MC.screen.slots[MODE_SLOT_IDX].stack # glowstone => remember, clock => play

    msg = [bookshelf, mode_stack].map(&:display_name).join(", ")
    puts "[*] #{msg}".white

    if msg =~ /Round:\s+(\d+), Remember the pattern/
      round = $1.to_i
      log msg
      if round == 16
        puts "[*] all done!".green
        return true
      end
      $stdout << "[.] Listen:"
      sounds = get_sounds(round, msg)
      wait_for(max_wait: nil) { MC.screen.slots[MODE_SLOT_IDX].stack.is_a?(:clock) }
      sleep(rand()/2)

      base = 
        if MC.screen.title =~ /Chronomatron \((.+)\)/
          FIRST_NOTE_SLOT[$1]
        else
          puts "[!] can't get base slot for level #{$1}".red
          12
        end

      $stdout << "[.] Play:  "
      sounds.each do |x|
        printf " %d", x
        MC.screen.slots[base+x].click!
        sleep(0.2 + rand()/2)
      end
      puts
    else
      sleep 0.1
    end
  end
end

solve if $0 == __FILE__
