# frozen_string_literal: true
require 'stringio'

class BaseHelper
  HUD_TEXT_TTL = 50

  attr_accessor :debug

  def handle screen
    MC.add_hud_text! "#{self.class}", color: 0x00ff00, x: -screen.x-6, y: screen.y+5, ttl: HUD_TEXT_TTL
    @log = StringIO.new
    handle_screen screen
    _update_hud(ttl: HUD_TEXT_TTL) unless @log.size == 0
  end

  def _update_hud ttl: 0
    @log.rewind
    MC.add_hud_text! ansi2mc(@log.read), key: "helper_log", x: 1, y: -1, ttl: ttl
  end

  def puts *args
    @log.puts *args
    Kernel.puts *args
    _update_hud
  end

  def printf *args
    @log.printf *args
    Kernel.printf *args
    _update_hud
  end
end
