# frozen_string_literal: true
module MC
  module API

    RED = 0xff0000ff

    class << self

      def status!
        [{ command: "status", intArg: MC.last_tick }]
      end

      def lock_cursor! lock = true
        [{ command: "lockCursor", boolArg: lock }]
      end

      def close_screen! wait: true
        [{ command: "closeScreen", boolArg: wait }]
      end

      def say! what, quiet: false
        mc_msg, terminal_msg =
          if what['§']
            [what, mc2ansi(what)]
          elsif what["\e["]
            [ansi2mc(what), what]
          else
            [what, what] # what? )
          end
        unless quiet
          ts = Time.now.strftime("%H:%M:%S")
          puts terminal_msg.sub(/\[.\]/, "\\0 #{ts}")
        end
        [{ command: "say", stringArg: mc_msg }]
      end

      def chat! what, quiet: false
        mc_msg, terminal_msg =
          if what['§']
            [what, mc2ansi(what)]
          elsif what["\e["]
            [ansi2mc(what), what]
          else
            [what, what] # what? )
          end
        unless quiet
          ts = Time.now.strftime("%H:%M:%S")
          puts terminal_msg.sub(/\[.\]/, "\\0 #{ts}")
        end
        [{ command: "chat", stringArg: mc_msg }]
      end

      def outline_entity! uuid, color = RED
        color =
          case color
          when Integer
            color
          when false
            0
          when true
            RED
          when Hash
            raise "invalid argument: #{color.inspect}" unless color[:color]
            return outline_entity! uuid, color[:color]
          end

        [{ command: "outlineEntity", stringArg: uuid, longArg: color }]
      end

      def register_command! command
        [{ command: "registerCommand", stringArg: command }]
      end

      def clear_spam_filters!
        [{ command: "clearSpamFilters" }]
      end

      def add_spam_filter! filter
        [{ command: "addSpamFilter", stringArg: filter }]
      end

      def get_entities! type: nil, expand: nil, result_key: nil, radius: nil
        if radius
          expand = { x: radius, y: radius, z: radius }
        end
        [{ command: "entities",
          stringArg: type,
          expand: expand,
          resultKey: result_key,
        }]
      end
      alias :entities! :get_entities!

      def get_sounds! prev_index: nil
        [{ command: "sounds", intArg: prev_index }]
      end

      def get_particles! prev_index: nil
        [{ command: "particles", intArg: prev_index }]
      end

      def get_messages! prev_index: nil
        [{ command: "messages", intArg: prev_index }]
      end

#      def messages! filter: ""
#        [{ command: "messages", stringArg: filter}]
#      end

      def click_screen_slot! slot_id, button: LEFT, action_type: "PICKUP"
        [{ command: "clickScreenSlot", intArg: slot_id, intArg2: button, stringArg: action_type }]
      end

      def click_inventory_slot! slot_id, button: LEFT, action_type: "PICKUP"
        [{ command: "clickSlot", intArg: slot_id, intArg2: button, stringArg: action_type }]
      end

      def add_hud_text! text, x:, y:, color: 0xcccccc, ttl: 0, key: nil
        [{ command: "HUD.addText", stringArg: text.to_s, x: x, y: y, color: color, ttl: ttl, stringArg2: key }]
      end

      def set_overlay_message! text, tint: false, ttl: nil
        [{ command: "setOverlayMessage", stringArg: text.to_s, boolArg: tint, intArg: ttl }]
      end

      def raytrace! range:, liquids: false, entities: true, result_key: nil
        flags = 0x10 # SHAPE_OUTLINE
        flags += 1 if liquids
        flags += 2 if entities
        [{ command: "raytrace", floatArg: range, intArg: flags, resultKey: result_key }]
      end

      SIDES = {
        down:  1,
        up:    2,
        north: 4,
        south: 8,
        west: 16,
        east: 32,
      }

      def look_at! pos, delay: nil
        pos = pos.to_h if pos.is_a?(Pos)
        delay ||= (20+rand(20))
        [{ command: "lookAt", target: pos, delay: delay }]
      end

      # returns true/false
      # reach distance will be set to default if zero
      def look_at_block! pos, delay: nil, reach: 0, sides: nil, side: nil, delay_next: nil
        pos = pos.to_h if pos.is_a?(Pos)
        raise "#{pos.inspect} is not a hash" unless pos.is_a?(Hash)
        delay ||= 10 + rand(12)
        isides = 0
        if side
          isides = SIDES[side.to_sym]
        elsif sides && sides.any?
          sides.each do |s|
            isides += SIDES[s.to_sym]
          end
        end
        [{ command: "lookAtBlock", target: pos, delay: delay, floatArg: reach, intArg: isides, delayNext: delay_next }]
      end

      def hide_entity! uuid
        [{ command: "hideEntity", stringArg: uuid }]
      end

      def hide_block! pos
        [{ command: "hideBlock", target: pos }]
      end

      def swap_slots! i1, i2
        raise "#{i1.inspect} is not an integer!" unless i1.is_a?(Integer)
        raise "#{i2.inspect} is not an ingeger!" unless i2.is_a?(Integer)
        [{ command: "Screen.swapSlots", intArg: i1, intArg2: i2 }]
      end

      def lock_slot! slot_id, sync_id: -1, lock: true
        [{ command: "Screen.lockSlot", intArg: slot_id, intArg2: sync_id, boolArg: lock }]
      end

      def copy_slot! src:, dst:
        raise unless src.is_a?(Integer)
        raise unless dst.is_a?(Integer)
        [{ command: "Screen.copySlot", intArg: src, intArg2: dst }]
      end

      def right_click! delay: nil
        delay ||= 50+rand(10)
        [{ command: "key", stringArg: "key.mouse.right", delay: delay }]
      end

      # hand is not a mouse button!
      MAIN_HAND = 0
      OFF_HAND  = 1

      HANDS = {
        left: MAIN_HAND,
        right: OFF_HAND,
      }

      def interact_item! hand: MAIN_HAND, delay_next: nil
        hand = HANDS[hand] || hand
        [{ command: "interactItem", intArg: hand, delayNext: delay_next }]
      end

      # target = optional blockPos
      # side   = optional side of blockPos
      # XXX got ban for this call
      def interact_block! hand: MAIN_HAND, delay_next: nil #, target: nil, side: nil
        target = nil
        side = nil
        hand = HANDS[hand] || hand
        [{ command: "interactBlock", intArg: hand, delayNext: delay_next, target: target, stringArg: side }]
      end

      # either uuid or network_id
      def interact_entity! uuid: nil, network_id: nil, reach: ENTITY_REACHABLE_DISTANCE, hand: MAIN_HAND, delay_next: nil
        hand = HANDS[hand] || hand
        [{ command: "interactEntity", stringArg: uuid, floatArg: reach, intArg: hand, intArg2: network_id, delayNext: delay_next }]
      end

      def attack_entity! uuid:, reach: ENTITY_REACHABLE_DISTANCE, delay_next: nil
        [{ command: "attackEntity", stringArg: uuid, floatArg: reach, delayNext: delay_next }]
      end

      def attack!
        [{ command: "attack" }]
      end

      def select_slot! n, delay_next: nil
        raise "invalid slot" unless (0..8).include?(n)
        [{ command: "selectSlot", intArg: n, delayNext: delay_next }]
      end

      # target = optional blockPos
      # side   = optional side of blockPos
      def break_block! target: nil, side: nil, delay_next: nil, oneshot: false
        [{ command: "startBreakingBlock", target: target, stringArg: side, delayNext: delay_next, boolArg: oneshot }]
      end

      def set_pitch_yaw! pitch: nil, yaw: nil, delay: 20, delay_next: nil
        [{ command: "setPitchYaw",
           floatArg: pitch || MC.player.pitch,
           floatArg2: yaw || MC.player.yaw,
           delay: delay,
           delayNext: delay_next,
        }]
      end

      def travel! *dirs, amount: 1
        target = {x: 0, y: 0, z: 0}
        dirs.each do |dir|
          case dir
          when Hash
            target = dir
          when :left
            target[:x] = amount
          when :right
            target[:x] = -amount
          when :up
            target[:y] = amount
          when :down
            target[:y] = -amount
          when :forward, :fwd
            target[:z] = amount
          when :backward, :back
            target[:z] = -amount
          else
            raise "invalid direction: #{dir.inspect}"
          end
        end
        [{ command: "travel", target: target }]
      end

      def press_key! key, delay: 0
        key = "key.keyboard.#{key}" if key =~ /\A\w+\Z/
        [ { command: "key", stringArg: key, delay: delay } ]
      end

      def release_key! key
        press_key! key, delay: -1
      end

      def blocks!(
        radius: BLOCK_REACHABLE_DISTANCE,
        radiusY: BLOCK_REACHABLE_DISTANCE,
        offset: { x: 0, y: 1, z: 0 },
        expand: nil,
        skip_air: true,
        result_key: nil,
        string_arg: nil,
        filter: nil,
        target: nil,
        box: nil
      )
        expand ||= { x: radius, y: radiusY, z: radius } unless box
        
        [{
          command: "blocksRelative",
          expand: expand,
          offset: offset,
          boolArg: !skip_air,
          resultKey: result_key,
          stringArg: string_arg,
          stringArg2: filter,
          target: target,
          box: box,
        }]
      end

      def get_entity! uuid:
        [{ command: "getEntityByUUID", stringArg: uuid }]
      end

      def add_particle! pos, speed: nil
        pos = pos.to_h if pos.is_a?(Pos)
        speed = speed.to_h if speed.is_a?(Pos)
        [{ command: "addParticle", target: pos, offset: speed }]
      end

    end # class << self
  end # API
end # MC
