#!/usr/bin/env ruby
require_relative '../autoattack'

LOG_FNAME = "~/minecraft/logs/latest.log"

# slots:
#
#      04      round
#  12  13  14
#  21  22  23
#  30  31  32
#
#      49      timer

def get_text stack
  map{ |stack| JSON.parse(stack.dig('tag', 'display', 'Name'))['extra'].map{ |x| x['text'] }.join }
end

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
      if line.to_s =~ /sound: minecraft:block\.note_block\.pling,.*pitch:\s*0\.(\d)/
        #puts "[d] #{line}"
        # 5 RED
        # 6 BLUE
        # 7 LIME
        r << ($1.to_i - 5)
        return r if r.size == round
      end
    end
  end
end

ROUND_SLOT_IDX = 4
MODE_SLOT_IDX = 49

def solve
  wait_for("Chronomatron screen", max_wait: nil) { MC.screen && MC.screen.title =~ /Chronomatron \(/ }
  loop do
    wait_for { MC.screen && MC.screen.slots[ROUND_SLOT_IDX].stack.is_a?(:bookshelf) }
    bookshelf = MC.screen.slots[ROUND_SLOT_IDX].stack
    mode_stack = MC.screen.slots[MODE_SLOT_IDX].stack # glowstone => remember, clock => play

    msg = [bookshelf, mode_stack].
      map{ |stack| JSON.parse(stack.dig('tag', 'display', 'Name'))['extra'].map{ |x| x['text'] }.join }.
      join(", ")
    puts "[.] #{msg}"

    if msg =~ /Round: (\d+), Remember the pattern/
      round = $1.to_i
      log msg
      if round == 16
        puts "[*] all done!".green
        return true
      end
      sounds = get_sounds(round, msg)
      wait_for(max_wait: nil) { MC.screen.slots[MODE_SLOT_IDX].stack.is_a?(:clock) }
      sleep(rand()/2)
      sounds.each do |x|
        MC.screen.slots[12+x].click!
        sleep(0.2 + rand()/2)
      end
    else
      sleep 0.1
    end
  end
end

solve if $0 == __FILE__
