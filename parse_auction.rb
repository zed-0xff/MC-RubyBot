#!/usr/bin/env ruby
require 'json'
require 'pp'
require 'yaml'
require 'awesome_print'
require_relative 'lib/item_db'

prices = Hash.new{ |k,v| k[v] = [] }

STACKED_ITEMS = [
    "Enchanted Bookshelf",
    "Sulphuric Coal",
    "Chum",
]

Dir["data/auctions.*.yml"].sort[-3..-1].each do |fname|
  puts fname
  auctions = YAML::load_file(fname)
  auctions.each do |auction|
    next unless auction['bin']
    item_name = auction['item_name'] # does not work for books!
    if auction['starting_bid'].nil?
      puts "[?] NULL starting_bid"
      next
    end

    next if item_name =~ /^New Year Cake/
    next if item_name =~ / Skin$/

    price = auction['starting_bid']
    # stacks of 64
    price /= 64 if STACKED_ITEMS.include?(item_name)

    if item_name =~ /Repelling Candle$/
      item_name = "Repelling Candle"
    end

    # leveled animals are also pricey
    item_name.sub! /^\[Lvl \d+\]/, ''

    # XXX starred items are more expensive!
    item_name.tr! "✿✪◆⚚✦➊➋➌➍➎", ""
    item_name.strip!

#    if prices[item_name].size > 5
#      prices[item_name][0] = [price, prices[item_name][0]].min
#    else
      prices[item_name] << price
#    end
  end
end

def strip_prefix item_name
  item_name.sub(/^(Light|Mythic|Spicy|Renowned|Wise|Pure|Fierce|Fruitful|Fabled|Necrotic|Legendary|Unreal|Giant|Ancient|Titanic|Smart|Heavy|Clean|Rich|Heroic|Precise|Fierce|Sharp|Withered|Jaded|Suspicious|Epic|Unyielding|Fleet|Heated|Auspicious|Odd|Fast|Dirty) /,'')
end

possible_prefixes = Hash.new(0)
fails = 0
h = {}
prices.each do |item_name, item_prices|
  next if item_prices.size < 3
  min_price = item_prices.sort[1..-1].min # use 2nd min
  printf "%10d  %s\n", min_price, item_name
  if (item_id = ItemDB.name2id(item_name))
    h[item_id] = min_price
  elsif (item_id = ItemDB.name2id(strip_prefix(item_name)))
    h[item_id] = min_price if !h[item_id] || h[item_id] > min_price
  else
    puts "[?] no id for #{item_name.inspect}".yellow
    possible_prefixes[item_name.split.first] += 1
    fails += 1
  end
end
File.write("data/auction_min_prices.yml", h.to_yaml)

puts
puts "possible prefixes:"
possible_prefixes.sort_by(&:last).each do |k,v|
  next if v < 3
  printf "%4d %s\n", v, k
end

puts "[=] #{prices.size} prices, #{h.size} ids, #{fails} fails"
