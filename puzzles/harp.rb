#!/usr/bin/env ruby
require_relative '../lib/common'

LOG_FNAME = "~/minecraft/logs/latest.log"

ACCURACY = (ARGV.first || "0.9999").to_f
puts "[.] accuracy = #{ACCURACY}"

#MC.cache_ttl = 0.2

#look_at [-394.5, 111.2, 33.3]
#press_key "key.mouse.right", 50

wait_for("Harp", delay: 0.5, max_wait: nil){
  look_at [-394.5, 111.2, 33.3]
  press_key "key.mouse.right", 50
  sleep(rand()*3)
  MC.screen && MC.screen.title =~ /Harp/
}
melody = MC.screen.title.split("-", 2).last.strip
puts "[*] melody: #{melody}"

syncId = MC.screen.syncId

# slots:  37  38  39  40  41  42  43

def calc_avg_dt arr
  sum = 0
  n = 0
  arr.each_cons(2) do |a,b|
    sum += (b-a)
    n += 1
  end
  sum/n
end

slot_id = nil
cache = {}
@tprev = Process.clock_gettime(Process::CLOCK_MONOTONIC)
@step = 1

def play_note slot_id
  now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  dt = now - @tprev
  @tprev = now
  if rand() < ACCURACY
    @slots[slot_id].click!
  else
    slot_id += (rand(2) == 1) ? 1 : -1
    @slots[slot_id].click!
  end
  printf "[.] step %2d: dt=%5.3f note %d\n", @step, dt, slot_id
  @step += 1
end

File.open(File.expand_path(LOG_FNAME), "r") do |f|
  f.seek 0, :END
  @slots = slots = MC.screen.slots # we don't need to update them from mod
  while MC.screen && MC.screen&.syncId == syncId
    line = f.gets
    if line
      if line.strip =~ /setStackInSlot\((\d+), \d+, (.+)\) syncId=#{syncId}$/
        slot_id = $1.to_i
        stack = $2
        cache[slot_id] = stack
        next unless (slot_id in 37..43) && stack['quartz_block']

        nrepeat = 1
        while cache[slot_id-nrepeat*9]['_wool']
          nrepeat += 1
        end

        nrepeat.times do
          play_note slot_id
          sleep(0.2+rand()/5) if nrepeat > 1
        end
      elsif line["note_block.bass"]
        puts "[!] MISS".red
        exit 1
      end
    end
  end
end
