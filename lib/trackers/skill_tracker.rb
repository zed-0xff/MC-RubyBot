#!/usr/bin/env ruby
# frozen_string_literal: true

class SkillTracker
  def initialize
    @log = []
    @prevmsg = nil
  end

  def track! status
    case status['overlay']
    when %r!§3\+([0-9.]+) (\w+) \(([^/]+)/([^)]+)\)!
    when %r!§3\+[\d.]+ \w+ \([\d.]+%\)!
    else
      return
    end

    msg = $&

    return if @prevmsg == msg
    @prevmsg = msg

    @log << msg
    @log.pop if @log.size > 10
    #p [$1, $2, $3, $4]
    [msg]
  end
end

if $0 == __FILE__
  require_relative '../common'
  tracker = SkillTracker.new
  loop do
    tracker.track! MC.status
    sleep 1
    MC.invalidate_cache!
  end
end
