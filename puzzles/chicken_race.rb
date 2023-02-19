#!/usr/bin/env ruby
require_relative '../lib/common'

MC.cache_ttl = 0

@prev_cp = nil
@prev_yaw = nil
@prev_space = nil

@prev_try = []
@route = []
@prev_tick = MC.tick
@tick0 = @prev_tick

TIME_SHIFT = -3

def record cp_limit = 10
  loop do
    status = MC.status
    overlay = status['overlay']

    if @prev_cp && @prev_cp >= cp_limit
      fname = "route_#{@prev_cp}_#{@prev_try[@prev_cp]}.yml"
      if !File.exist?(fname)
        prev_files = Dir["route_#{@prev_cp}_*"]
        msg = "[=] #{fname}"
        if prev_files.any?
          best = prev_files.sort.last
          if fname > best
            msg = msg.green
          else
            msg = msg.red
          end
        end
        say msg
        File.write fname, @route.to_yaml
      end
    end

    unless overlay =~ %r|CHICKEN RACING §e00:([0-9.]+)     §b(\d+)/(\d+) |
      @prev_cp = nil
      @prev_yaw = nil
      @prev_space = nil
      @route.clear
      next
    end

    next if status['tick'] == @prev_tick
    @prev_tick = status['tick']

    time  = $1.to_f
    cp    = $2.to_i
    yaw   = status.dig('player','yaw')
    space = status.dig('input', 'key.keyboard.space', 'state')

    if @prev_yaw != yaw || @prev_space != space
      @tick0 = status['tick'] if @route.empty?
      dtick  = status['tick'] - @tick0
      @route << [time, cp, yaw, space, dtick]
    end

    if @prev_cp && @prev_cp < cp
      #    p [time, cp, status.dig('player','yaw'), status.dig('input', 'key.keyboard.space', 'state')]
      if @prev_try[cp]
        dtime = @prev_try[cp]-time
        printf "%2d %6.3f ", cp, time
        if dtime < 0
          printf "%.3f\n".green, dtime
        else
          printf "+%.3f\n".red, dtime
        end
      else
        printf "%2d %6.3f\n", cp, time
      end
      @prev_try[cp] = time
    end

    @prev_cp = cp
    @prev_yaw = yaw
    @prev_space = space
  end
rescue Interrupt
  exit
end

def replay fname
  @route = YAML::load_file fname
  step = 0
  rstep = @route[step]
  @prev_cp = nil
  @tick0 = nil

  MC.say! "ready".green

  loop do
    MC.invalidate_cache!
    status = MC.status
    overlay = status['overlay']
    unless overlay =~ %r|CHICKEN RACING §e00:([0-9.]+)     §b(\d+)/(\d+) |
      next
    end

    time  = $1.to_f
    cp    = $2.to_i

    if @prev_cp && cp < @prev_cp
      step = 0
      rstep = @route[step]
    end

    if rstep.nil?
      say "NOW FLY!!!".red
      return record
    elsif @route[step+1].nil?
      say "PREPARE!!!".yellow
    end

    if step == 0 && @tick0.nil?
      @tick0 = status['tick']
    end

    if @prev_tick == status['tick']
      next
    end
    @prev_tick = status['tick']

    dtick = status['tick'] - @tick0

    while rstep && dtick >= rstep[4] + TIME_SHIFT
      MC.say! "step #{step+1} of #{@route.size}"
      printf "[.] %3d %s\n", step, rstep.inspect
      if (cp-rstep[1]).abs > 1
        puts "[!] bad fly :(".red
        release_key('space')
        exit 1
      end
      MC.set_pitch_yaw! yaw: rstep[2], delay: 0
      if rstep[3] == 1 && @route[step-1][3] == 0
        press_key('space', 0)
      elsif rstep[3] == 0 && @route[step-1][3] == 1
        release_key('space')
      end
      step += 1
      rstep = @route[step]
    end

    @prev_yaw   = status.dig('player','yaw')
    @prev_space = status.dig('input', 'key.keyboard.space', 'state')

    @prev_cp = cp
  end
end

def cleanup
  fnames = Dir["route_*.yml"]
  h = {}
  fnames.sort.each do |fname|
    next unless fname =~ /route_(\d+)_/
    step = $1.to_i
    h[step] ||= []
    h[step] << fname
  end
  h.each do |step, fnames|
    next if fnames.size == 1
    fnames[0..-2].each do |fname|
      File.unlink(fname)
    end
  end
end

case ARGV[0]
when nil
  MC.say! "start from scratch!".green
  record
when "cleanup"
  cleanup
else
  replay ARGV[0]
end
