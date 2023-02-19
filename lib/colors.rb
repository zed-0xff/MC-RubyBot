require 'awesome_print'
# frozen_string_literal: true

MC2ANSI = {
  "§2" => "\e[0;32m", # dark_green
  "§4" => "\e[0;31m", # dark_red
  "§5" => "\e[0;35m", # dark_purple
  "§6" => "\e[0;33m", # gold -> yellowish
  "§7" => "\e[1;30m", # gray
  "§9" => "\e[1;34m", # blue
  "§a" => "\e[1;32m", # green
  "§b" => "\e[1;36m", # cyan
  "§c" => "\e[1;31m", # red
  "§d" => "\e[1;35m", # light_purple
  "§e" => "\e[1;33m", # yellow
  "§f" => "\e[1;37m", # white
}.freeze

ANSI2MC = (MC2ANSI.invert.merge("\e[0m" => "§r")).freeze

def mc2ansi s
  return s unless s['§']
  s.gsub(/§./){ |x| MC2ANSI[x] || x } + "\e[0m"
end

def ansi2mc s
  return s unless s["\e["]
  s.gsub(/\e\[[0-9;]+m/){ |x| ANSI2MC[x] || x }
end

def strip_colors s
  return s unless s['§']
  s.gsub(/§./,'')
end

COLORS = (
  %w(gray red green yellow blue purple cyan white) +
  %w(redish greenish yellowish blueish purpleish cyanish whiteish)
).freeze

COLOR_ALIASES = {
  "aqua"        => "cyan",
  "coal"        => "gray",
  "dark_aqua"   => "blue",
  "dark_gray"   => "gray",
  "dark_purple" => "purpleish",
  "dark_red"    => "redish",
  "diamond"     => "cyan",
  "emerald"     => "green",
  "gold"        => "yellowish",
  "gray"        => "white",
  "lapis"       => "blue",
  "light_blue"  => "cyan",
  "light_purple"=> "purple",
  "lime"        => "green",
  "mithril"     => "cyan",
  "pink"        => "redish", # or purple?
  "poppy"       => "red",
}.freeze

def get_color string
  if (calias = COLOR_ALIASES.keys.find { |c| string[c] })
    COLOR_ALIASES[calias]
  elsif (color = COLORS.find { |c| string[c] })
    color
  else
    nil
  end
end

def colorize string
  (color = get_color string) ? string.send(color) : string
end
