# frozen_string_literal: true

class Brain
  class Rule
    attr_reader :name, :brain

    def initialize rule, name: nil, brain:
      @brain = brain
      @name = name
      @actions = rule['actions'] || [rule['action']]
      @zones = rule['zones']
      @maps = rule['maps']
      @not_zones = rule['not_zones']
      @age = rule['age']
      @inertia = rule['inertia'] || Brain::INERTIA
      @sides = rule['sides']
      @player_facing = rule['player_facing']
      @enabled = rule.fetch('enabled', true)
      @oneshot = !!rule['oneshot']
      @prev_breaks = []
      @prev_interacts = []
      @min_y = rule['min_y']
      @max_y = rule['max_y']

      if rule['tool']
        @tools = [_parse_tool(rule['tool'])]
      elsif rule['tools']
        @tools = rule['tools'].map { |t| _parse_tool(t) }
      else
        @tools = []
      end
      @tools.compact!
    end

    def oneshot?
      @oneshot
    end

    def to_s
      "#<Brain::Rule name=#{name.inspect}>"
    end

    def player
      brain.player
    end

    def _parse_tool tool
      case tool
      when /^any$/i
        nil
      when %r|^:|
        tool[1..-1].to_sym
      when %r|^/.+/$|
        Regexp.new(tool[1..-2])
      else
        tool
      end
    end

    def inspect
      "#<Brain::Rule @name=#{@name.inspect}>"
    end

    def run! block, status
      return unless @enabled
      return if (@prev_block == block) && (brain.current_tick - @prev_tick) < @inertia
      @prev_tick = brain.current_tick
      @prev_block = block
      return if @not_zones && @not_zones.include?(MC.current_zone)
      return if @zones && !@zones.include?(MC.current_zone)
      return if @maps && !@maps.include?(MC.current_map)
      return if @age && block['age'] != @age
      return if @sides && !@sides.include?(block['side'])
      return if @player_facing && ! @player_facing.include?(player.facing)
      return if @min_y && block['pos']['y'] < @min_y
      return if @max_y && block['pos']['y'] > @max_y

      prev_slot = player.inventory.selected_slot
      if @tools && @tools.any?
        return unless @tools.find { |t| select_tool(t) }
      end

      if brain.debug
        if player.inventory.selected_slot != prev_slot
          puts "[d] rule #{@name.inspect}: selected tool #{player.current_tool.display_name} (was: #{prev_tool.display_name})"
        end
        #puts "[d] rule #{@name.inspect}: running action #{@action.inspect}"
      end

      @actions.each do |action|
        case action
        when 'hold_left'
          brain.hold_left! ticks: @inertia
        when 'hold_right'
          brain.hold_right!
        when 'release'
          brain.release!
        when 'interact_block'
          MC.interact_block! delay_next: 1
        when 'break_block'
          # XXX dangerous!! might break block farther than reach!
          pos = block['pos']
          if @prev_breaks.include?(pos)
            if @oneshot
              block2 = Array(status['blocks_around_looking_at']).
                find{ |x| x['id'] == block['id'] && !@prev_breaks.include?(x['pos']) }
              pos = block2&.dig('pos')
            else
              pos = nil
            end
          end
          if pos
            while @prev_breaks.size > 4
              @prev_breaks.pop
            end
            @prev_breaks << pos

            return Proc.new{ |mc|
              mc.break_block! target: pos, side: block['side'].upcase, delay_next: 1, oneshot: @oneshot
            }
          end
        when 'break_max'
          d = 0
          return Proc.new do |mc|
            mc.break_block! target: block['pos'], side: block['side'].upcase, delay_next: d, oneshot: true
            blocks = Array(status['blocks_around_looking_at']).
              find_all{ |x| x['id'] == block['id'] && !@prev_breaks.include?(x['pos']) }
            if blocks.any?
              blocks.each do |b|
                next if b['pos'] == block['pos']
                next if b['pos']['y'] != block['pos']['y']
                next if b['age'] != block['age']
                mc.break_block! target: b['pos'], side: block['side'].upcase, delay_next: d, oneshot: true
                d = 1 - d # break 2 blocks per tick
              end
            end
          end
        when 'break_max_3d'
          d = 0
          return Proc.new do |mc|
            mc.break_block! target: block['pos'], side: block['side'].upcase, delay_next: d, oneshot: true
            blocks = Array(status['blocks_around_looking_at']).
              find_all{ |x| x['id'] == block['id'] && !@prev_breaks.include?(x['pos']) }
            if blocks.any?
              blocks.each do |b|
                next if b['pos'] == block['pos']
                next if b['age'] != block['age']
                mc.break_block! target: b['pos'], side: block['side'].upcase, delay_next: d, oneshot: true
                d = 1 - d # break 2 blocks per tick
              end
            end
          end
# XXX got ban for this call
#        when 'interact_block_max'
#          d = 0
#          return Proc.new do |mc|
#            mc.interact_block! target: block['pos'], side: block['side'].upcase, delay_next: d
#            blocks = Array(status['blocks_around_looking_at']).
#              find_all{ |x| x['id'] == block['id'] && !@prev_interacts.include?(x['pos']) }
#            if blocks.any?
#              blocks.each do |b|
#                next if b['pos'] == block['pos']
#                next if b['pos']['y'] != block['pos']['y']
#                next if b['age'] != block['age']
#                mc.interact_block! target: b['pos'], side: block['side'].upcase, delay_next: d
#                d = 1 - d # interact 2 blocks per tick
#              end
#            end
#          end
        when 'mine_static'
          # TBD?
          return false
        else
          puts "[?] unknown action: #{action.inspect}"
          return false
        end
      end
      true
    end
  end
end
