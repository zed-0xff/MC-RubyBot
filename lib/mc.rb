require_relative 'mc/api'
require 'open-uri'
require 'json'
require 'net/http'

module MC
  TICKS_PER_SEC = 20

  @status = nil
  @status_timestamp = nil
  @cache_ttl = 1.0
  @exit_on_esc = true
  @tick = 0
  @stubborn = true
  @debug = false

  class << self
    attr_accessor :cache_ttl, :exit_on_esc, :stubborn, :debug

    def debug?
      @debug
    end

    # might issue query
    def tick
      @tick = status['tick']
    end

    # always cached one
    def last_tick
      @tick
    end

    def current_zone
      status['sidebar'].find{ |x| x['⏣'] }.to_s.sub('⏣','').strip
    end

    def current_server
      # "08/06/22 m72B"
      status['sidebar'] &&
        status['sidebar'].size > 1 &&
        status['sidebar'][1].split.last
    end

    def current_map
      s = status.dig('playerList', 41).to_s
      s.start_with?("Area:") && s.sub(/^Area:/, '').strip
    end

    def screen
      status['screen'] && Screen.new(status['screen'])
    end

    def invalidate_cache!
      @status = nil
    end

    def player
      msg_shown = false
      loop do
        return Player.new(status) if status['player']
        unless msg_shown
          puts "[.] waiting for player status ..".gray 
          msg_shown = true
        end
        sleep 1
      end
    end

    def _parse_status status
      @status = status
      @tick = @status['tick'].to_i
      if (esc=@status.dig('input', "key.keyboard.escape"))
        if @exit_on_esc && esc['state'] == 1 && esc['age'] >= 5
          MC.chat! "#stop"
          MC.say! "[!!!] aborting all on ESC".red
          exit
        end
      end
      @status_timestamp = Time.now
    end

    def status
      if @status.nil? || ((Time.now-@status_timestamp) > @cache_ttl)
        puts "[d] getting status".yellow if debug?
        data = URI.open("http://127.0.0.1:9999").read
        begin
          _parse_status JSON.parse(data)
        rescue JSON::ParserError
          puts data
          raise
        end
      end
      @status
    rescue Errno::ECONNREFUSED, OpenURI::HTTPError, EOFError => e
      puts "[!] #{e}".red
      sleep 1
      retry
    end

    # same as status(), but:
    #   a) tick-aware (will not run more than once per tick)
    #   b) uses same endpoint as all other commands, so can be combined with them in one script
#    def status!

#    end

    def script debug: false, &block
      script = Script.new
      script.instance_eval &block
      script = script.to_script
      if debug
        puts "[d] script:"
        pp script
      end
      run_script! script
    end

    @before_send = nil

    def before_send &block
      @before_send = block
    end

    def run_script! script
      return nil if script.empty?
      #puts "[d] #{script}"
      if @before_send
        @before_send.call(script)
      end

      resp = nil
      100.times do
        resp = Net::HTTP.post(ACTION_URI, script.to_json)
        code = resp.code.to_i
        puts "[d] #{resp.code}".yellow unless code == 200 || code == 420
        if code == 420
          # reschedule remaining script
          script = JSON.parse(resp.body)['remainingScript']
          commands = script.map{ |a| a['command'] }.join(", ")
          puts "[.] rescheduled #{script.size} actions to next tick: #{commands}".gray if debug?
          sleep(1.0/TICKS_PER_SEC/2)
        else
          break
        end
      end

      r = JSON.parse(resp.body)
      if r['status'] == 'full'
        _parse_status(r)
      elsif r['tick']
        @tick = r['tick']
      end
      @prev_script = script
      r
    rescue Errno::ECONNREFUSED => e
      sleep 1
      retry
    rescue JSON::ParserError => e
      $stderr.puts "[!] #{e.class}: #{e}".red
      $stderr.puts "    prev_script:"
      PP.pp(@prev_script, $stderr)
      $stderr.puts "    script:"
      PP.pp(script, $stderr)
      e.backtrace.each do |line|
        $stderr.puts "    #{line}".red
      end
      if @stubborn
        sleep 1
        retry
      else
        exit 1
      end
    end

    def has_mod? mod_id
      mods[mod_id]
    end

    def mods
      @mods ||= Hash[
        *run_script!([{ command: "getMods" }])['mods'].map{ |m|
          [m['id'], m]
        }.flatten
      ]
    end

    # might return nil if pets are hidden!
#    def current_pet
#    end
#
#    def select_pet! pet
#    end

    def item_matcher id
      case id
      when Regexp
        Proc.new { |x| x.skyblock_id =~ id }
      when /^[A-Z0-9_:]+$/
        # skyblock_id
        Proc.new { |x| x.skyblock_id == id }
      when Symbol
        # minecraft id
        id = "minecraft:#{id}"
        Proc.new { |x| x.id == id }
      else
        raise "[?] don't know how to find #{id.inspect}"
      end
    end

    def select_tool tool_id, **kwargs
      matcher = item_matcher(tool_id)

      ct = player.current_tool
      return ct if ct && matcher.call(ct)

      tool = player.inventory[0..7].find{ |x| x && matcher.call(x) }

      if tool
        select_slot!(tool['Slot'], **kwargs)
        tool
      else
        puts "[?] tool #{tool_id.inspect} not found"
        nil
      end
    end

    def method_missing mname, *args, **kwargs
      key = mname.to_s
      if key.end_with?("!")
        # MC API command
        script = API.send(mname, *args, **kwargs)
        run_script! script
      elsif status.key?(key) && args.empty?
        @status[key]
      else
        raise "wtf: #{mname}"
      end
    rescue Errno::ECONNREFUSED, OpenURI::HTTPError, EOFError => e
      puts "[!] #{e}".red
      sleep 1
      retry
    end
  end

  class Script
    def initialize
      @commands = []
    end

    def method_missing mname, *args, **kwargs
      @commands << [mname, args, kwargs]
    end

    def to_script
      @commands.map do |c, args, kwargs|
        API.send(c, *args, **kwargs)
      end.flatten
    end
  end
end
