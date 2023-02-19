require_relative 'lib/common'
require 'zlib'

PRICES_TTL = 12*3600

def auction_price id
  @auction_prices ||=
    begin
      YAML::load_file "data/auction_min_prices.yml"
#      prices_url = "https://moulberry.codes/auction_averages_lbin/3day.json.gz"
#      fname = File.basename(prices_url)
#      if !File.exist?(fname) || Time.now-File.mtime(fname) > PRICES_TTL
#        data = URI.open(prices_url).read
#        File.binwrite(fname, data)
#      end
#      JSON.parse(Zlib::GzipReader.open(fname).read)
    end
  @auction_prices[id]
end

def bazaar_price id, type="sellPrice"
  @bazaar_prices ||=
    begin
      prices_url = "https://api.hypixel.net/skyblock/bazaar"
      fname = "data/bazaar.json"
      if !File.exist?(fname) || Time.now-File.mtime(fname) > PRICES_TTL
        data = URI.open(prices_url).read
        File.write(fname, data)
      end
      JSON.parse(File.read(fname))
    end
  @bazaar_prices.dig("products", id, "quick_status", type)
end

def npc_price id
  @npc_prices ||=
    begin
      url = "https://hysky.de/api/npcprice"
      fname = "data/npc_prices.json"
      if !File.exist?(fname) || Time.now-File.mtime(fname) > PRICES_TTL
        data = URI.open(url).read
        File.write(fname, data)
      end
      JSON.parse(File.read(fname))
    end
  @npc_prices[id].to_i
end

def format_money value
  if value > 9_999_999
    "%4dM".green % (value/1_000_000)
  elsif value > 999_999
    "%4.1fM".green % (value/1_000_000.0)
  elsif value > 1000
    "%4dk" % (value/1_000.0).round
  else
    "%5d" % value
  end
end

def read_recipes
  recipes_dir = File.expand_path "~/minecraft/config/skyblocker/item-repo/items"
  Dir[File.join(recipes_dir, "*.json")].each do |fname|
    item = JSON.parse(File.read(fname))
    yield item unless item['vanilla']
  end
  recipes_dir = "recipes"
  Dir[File.join(recipes_dir, "*.json")].each do |fname|
    item = JSON.parse(File.read(fname))
    yield item unless item['vanilla']
  end
end

def recipe_materials recipe
  h = Hash.new(0)
  recipe.values.each{ |x| a=x.split(":"); h[a[0]] += a[1].to_i unless x.empty? }
  h
end

def get_possible_recipes inventory
  possibles = []
  read_recipes do |item|
    recipe = item['recipe']
    next if !recipe || recipe.empty?
    recipe = recipe_materials(recipe)
    npossible = 999
    recipe.each do |ingr_id, count|
      have = inventory[ingr_id].to_i
      if have < count
        npossible = 0
        break 
      end
      npossible = [npossible, have/count].min
      break if npossible == 0
    end
    if npossible != 0
      dst_id = item['internalname']
      price = npc_price(dst_id) # (bazaar_price(dst_id) || auction_price(dst_id)).to_i
      possibles << [npossible, price, item, inventory[dst_id].to_i, item['crafttext']]
    end
  end
  possibles
end

def get_profitable_recipes inventory
  results = []
  read_recipes do |item|
    next if item['vanilla']

    dst_id = item['internalname']

    dst_price = bazaar_price(dst_id)
    if dst_price
      next if dst_price.to_i < 8_000
    else
      dst_price = auction_price(dst_id)
      next if dst_price.to_i < 400_000
    end

    recipe = item['recipe']
    next if !recipe || recipe.empty?

    recipe = recipe_materials(recipe)

    src_price = 0.0
    src_have = 0
    src_total = 0
    recipe.each do |ingr_id, count|
      src_total += count
      have = inventory[ingr_id].to_i
      src_have += have
      to_buy = count - have
      next if to_buy == 0

      ingr_price = bazaar_price(ingr_id) || auction_price(ingr_id) || 999_999_999
      src_price += count*ingr_price
    end

    next if dst_price < src_price
    next if dst_price/src_price < 1.5

    results << [dst_id, dst_price, src_price, src_have, src_total, item['crafttext']]
  end
  results
end

def show_possible_recipes possibles
  if ENV['ALL'].nil?
    inventory = TotalInventory.new.data['total']
    max_minion_levels = Hash.new(0)
    inventory.each do |k,n|
      if k =~ /^(.+)_GENERATOR_(\d+)/
        max_minion_levels[$1] = [max_minion_levels[$1], $2.to_i].max
      end
    end
    possibles.delete_if do |npossible, price, item|
      k = item['internalname']
      k =~ /^(.+)_GENERATOR_(\d+)/ && $1.to_i <= max_minion_levels[$1]
    end
  end

  puts "[*] possible to make:"
  possibles.sort_by { |a| strip_colors(a.dig(2, 'displayname')) }.each do |npossible, price, item, already_have, crafttext|
    name = strip_colors(item['displayname'])
    if ENV['ALL'].nil?

      next if already_have > 0 && name =~ / (Rod|Talisman|Ring|Head|Bucket|Boots|Chestplate|Leggings|Helmet|Hat|Sack|Storage|Bow|Orb|Stinger|Sword|Can|Axe)$/
      next if already_have > 0 && name =~ / Minion /
    end

    printf "%s %3d %s %s %-30s %s\n", 
      format_money(price*npossible),
      npossible,
      format_money(price),
      mc2ansi(item['displayname'].ljust(35+item['displayname'].count('§')*2)),
      item['internalname'],
      (already_have > 0 ? "(have #{already_have}) ".green : '') + crafttext.to_s.sub(/^Requires:? /,'').gray
  end
end

namespace :analyze_log do
  desc "get intervals between normal hand swings"
  task :hand_swings do
    h = Hash.new(0)
    File.open(LOG_FNAME, "r") do |f|
      prev = 0
      while line = f.gets
        next unless line =~ /\[(\d+)\] SEND HandSwingC2SPacket/
        tick = $1.to_i
        delta = tick - prev
        h[delta] += 1 if delta < 50
        prev = tick
      end
    end
    ntotal = h.values.sum.to_f
    h.keys.sort.each do |k|
      v = h[k]
      rate = v/ntotal
      next if rate < 0.01
      printf "%3d %.2f %s\n", k, rate, "*"*(rate*100)
    end
    puts
    puts ntotal.to_i
  end

  # [=] 1247 swings, 300 hits, ratio = 0.241
  desc "get hit/miss ratio"
  task :hit_miss do
    require_relative 'lib/common'
    nhits = 0
    nswings = 0
    state = nil
    File.open(LOG_FNAME, "r") do |f|
      f.seek 0, :END
      loop do
        line = f.gets
        if line.nil?
          sleep 0.01
          next
        end

        case line
        when /HandSwingC2SPacket/
          nswings += 1
          state = :swing
        when /PlayerInteractEntityC2SPacket/
          if state == :swing
            nhits += 1 
            state = :interact
            if nhits % 10 == 0
              say sprintf("[=] %d swings, %d hits, ratio = %.3f", nswings, nhits, 1.0*nhits/nswings)
            end
          else
            puts "[-] hit in state #{state.inspect}"
          end
        when /Render thread|SPRINTING|CHAT|UpdateSelectedSlot|PlayerInteractItem/
          # ignore
        else
          p line
          # state = nil
        end
      end
    end
  end
end

desc "Show total inventory and its Net Worth :)"
task :inventory do
  require_relative 'total_inventory'
  inventory = TotalInventory.new.data
  ids2names = YAML::load_file "data/items/ids2names.yml"
  sum = 0
  inventory['total'].map do |id, count|
    price =
      if MC.player.ironman?
        npc_price(id)
      else
        [bazaar_price(id) || auction_price(id), npc_price(id), 0].compact.max
      end
    value = count * price
    sum += value
    [value, id]
  end.sort_by(&:first).each do |value, id|
    count = inventory['total'][id]
    next if count == 0
    if value == 0
      printf "[?]         %5d %-30s %s\n".yellowish, count, ids2names[id], id
    else
      printf "[.] %s %5d %s\n", format_money(value), count, ids2names[id]
    end
  end

  printf "\n[.] %s\n", format_money(sum)
end

namespace :inventory do
  desc "show possible recipes"
  task :recipes do
    require_relative 'total_inventory'
    inventory = TotalInventory.new.data['total']
    possibles = get_possible_recipes inventory

    show_possible_recipes possibles
  end

  namespace :recipes do
    desc "show level2 recipes (assume all L1 done)"
    task :l2 do
      require_relative 'total_inventory'
      inventory = TotalInventory.new.data['total']
      possibles = get_possible_recipes inventory
      possibles.each do |npossible, price, item|
        inventory[item['internalname']] ||= 0
        inventory[item['internalname']] += npossible
      end
      possibles2 = get_possible_recipes inventory

      show_possible_recipes(possibles2 - possibles)
    end

    desc "show level3 recipes (assume all L1 done)"
    task :l3 do
      require_relative 'total_inventory'
      inventory = TotalInventory.new.data['total']
      possibles = get_possible_recipes inventory
      possibles.each do |npossible, price, item|
        inventory[item['internalname']] ||= 0
        inventory[item['internalname']] += npossible
      end
      possibles2 = get_possible_recipes inventory

      possibles2.each do |npossible, price, item|
        inventory[item['internalname']] ||= 0
        inventory[item['internalname']] += npossible
      end
      possibles3 = get_possible_recipes inventory

      show_possible_recipes(possibles3 - possibles2 - possibles)
    end

    desc "show potentially profitable recipes from inventory"
    task :profitable_inventory do
      require_relative 'lib/item_db'
      require_relative 'total_inventory'
      inventory = TotalInventory.new.data['total']
      rows = get_profitable_recipes inventory
      rows.sort_by{ |row| row[1] / [row[2], 1.0].max }.each do |row|
        dst_id, dst_price, src_price, src_have, src_total, crafttext = row
        printf "[=]  %s  %s  %-30s  %s\n",
          format_money(dst_price),
          format_money(src_price),
          ItemDB.id2name(dst_id) || dst_id,
          crafttext.to_s.sub(/^Requires:? /,'').gray
      end
    end

    desc "show potentially profitable bz2ah recipes"
    task :bz2ah do
      require_relative 'lib/item_db'
      rows = []
      read_recipes do |item|
        next unless item['recipe']
        next if item['vanilla']

        dst_id = item['internalname']
        dst_price = [auction_price(dst_id), bazaar_price(dst_id)].compact.min
        next unless dst_price

        crafttext = item['crafttext']

        recipe = recipe_materials(item['recipe'])
        src_price = 0
        recipe.each do |ingr_id, count|
          if (pr=bazaar_price(ingr_id, 'buyPrice'))
            src_price += count*pr
          elsif (pr=auction_price(ingr_id))
            src_price += count*pr
          else
            src_price = nil
            break
          end
        end
        next unless src_price

        next if src_price > dst_price
        next if src_price > 10_000_000

        rows << [dst_id, dst_price, src_price, crafttext]
      end

      rows.sort_by{ |row| row[1] - row[2] }.each do |row|
        dst_id, dst_price, src_price, crafttext = row
        printf "[=]  %s = %s - %s  %-30s  %s\n",
          format_money(dst_price-src_price),
          format_money(dst_price),
          format_money(src_price),
          ItemDB.id2name(dst_id) || dst_id,
          crafttext.to_s.sub(/^Requires:? /,'').gray
      end
    end
  end # namespace recipes
end

namespace :skyblock do
  namespace :auctions do
    desc "fetch auctions"
    task :fetch do
      page = 0
      npages = nil
      auctions = []
      while npages.nil? || page < npages
        url = "https://api.hypixel.net/skyblock/auctions?page=#{page}"
        data = JSON.parse(URI.open(url).read)
        npages ||= data['totalPages']
        puts "[.] #{url} of #{npages}"
        page += 1
        auctions.append(*data['auctions'].find_all{ |a| a['bin'] })
      end
      File.write("data/auctions.%d.yml" % Time.now.to_i, auctions.to_yaml)
    end
  end # namespace auctions

  namespace :items do
    desc "fetch items"
    task :fetch do
      url = "https://api.hypixel.net/resources/skyblock/items"
      data = URI.open(url).read
      File.write "data/items.json", data
    end

    desc "prepare items"
    task :prepare do
      data = File.read "data/items.json"
      names2ids = {}
      ids2names = {}
      JSON.parse(data)["items"].each do |item|
        if names2ids[item["name"]]
          puts "[?] conflicting item name: #{item["name"].inspect}"
        else
          names2ids[item["name"]] = item["id"]
        end
        if ids2names[item["id"]]
          puts "[?] conflicting item id: #{item["id"].inspect}"
        else
          ids2names[item["id"]] = item["name"]
        end
      end
      File.write "data/items/names2ids.yml", names2ids.to_yaml
      File.write "data/items/ids2names.yml", ids2names.to_yaml
    end
  end
end

namespace :recipes do
  desc "find what's missing for recipe(s)"
  task :find do
    abort "gimme RE" unless ENV['RE']
    re = Regexp.new(ENV['RE'])

    thr = (ENV['THR'] || "10").to_i

    require_relative 'total_inventory'
    inventory = TotalInventory.new.data['total']
    found = {}
    read_recipes do |item|
      next unless item['recipe']
      next unless item['displayname'] =~ re

      dname = strip_colors(item['displayname'])
      next if found[dname]
      found[dname] = item

      recipe = recipe_materials(item['recipe'])

      src_total = 0
      have_total = 0
      recipe.each do |ingr_id, count|
        src_total += count
        have_total += [count, inventory[ingr_id].to_i].min
      end
      perc = 100.0*have_total/src_total
      next if perc < thr
      printf "[=] %-30s %3d%%\n", dname, perc
    end
  end
end

desc "console"
task :console do
  require_relative 'brain'
  # clear ARGV so IRB is not confused
  ARGV.clear
  require 'irb'
  IRB.start
end

desc "sound monitor"
task :sounds do
  require_relative 'lib/mc'
  prev_index = 0
  loop do
    r = MC.get_sounds!(since: prev_index)
    r['sounds'].each do |sound|
      puts sound.to_json
      prev_index = sound['index']
#      printf("[.] %5d: %s\n", sound['tick'], sound.inspect)
    end
    puts
    sleep 1
  end
end

desc "show guessed entity kind player is looking at"
task :entity_kind do
  MC.cache_ttl = 0.1
  seen = {}
  loop do
    if (e = MC.player.dig('looking_at', 'entity')) && !seen[e['network_id']]
      printf "[.] %7d name=%-20s mob=%s player=%s\n", e['network_id'], e['name'], is_mob?(e), is_player?(e)
      seen[e['network_id']] = true
    end
    sleep 0.1
  end
end

desc "show data_dir"
task :data_dir do
  puts MC.player.data_dir
end
