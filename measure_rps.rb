#!/usr/bin/env ruby
# frozen_string_literal: true
require "curses"
require "json"
require "open-uri"
require 'awesome_print'

class Array
  def avg
    inject(&:+) / size
  end
end

include Curses

N = 100

t0 = Time.now
niter = 0
ptimes = 0
max_ptime = 0
aptime = [0] * N
s = nil
data = nil


init_screen
begin
  crmode
  loop do
    niter += 1
    setpos(0, 0)
      begin
        data = ''
        data = URI.open("http://127.0.0.1:9999").read
        j = JSON.parse(data)
        ptime = j['processing_time'].to_f
        ptimes += ptime
        aptime[niter%N] = ptime
        max_ptime = ptime if ptime > max_ptime
        s = j.awesome_inspect(plain: true)
      rescue => e
        addstr "[!] #{e.class}: #{e.message}\n"
        addstr "[.] data size: #{data.size}\n" if data.respond_to?(:size)
        addstr "[.] data: #{data.inspect}\n"
        refresh
        sleep 1
      end
    clear
    addstr "[.] RPS: %3d, avg.ptime: %3.3fms, max.ptime: %3.3fms\n" % [(niter/(Time.now-t0)).round, ptimes/niter, max_ptime]
    addstr "[.] last %3d, avg.ptime: %3.3fms, max.ptime: %3.3fms\n" % [N, aptime.avg, aptime.max]
    addstr s.to_s
    refresh
    sleep 0.005
  end
rescue Interrupt
ensure
  close_screen
end
