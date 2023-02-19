class Inventory
  attr_reader :selected_slot, :data

  def initialize inventory, selected_slot=nil
    @selected_slot = selected_slot
    @stacks = inventory.map.with_index { |x,i| ItemStack.new(x.merge('Slot' => i)) }
    @data = inventory
  end

  def each
    @stacks.each do |stack|
      yield stack
    end
  end

  def count x
    r = 0
    matcher = item_matcher(x)
    @stacks.each do |stack|
      r += stack.size if matcher.call(stack)
    end
    r
  end

  def count_items
    h = Hash.new(0)
    @stacks.each do |stack|
      next if stack.empty?
      raise "[?] no skyblock id for #{stack.inspect}" unless stack.skyblock_id
      h[stack.skyblock_id] += stack.size
    end
    h
  end

  def free_slots_count
    @stacks[0..35].count(&:empty?)
  end

  def has_free_slots?
    @stacks[0..35].any?(&:empty?)
  end

  def full?
    @stacks[0..35].all? { |s| !s.empty? }
  end

#  def optimize!
#    pp @stacks.group_by(&:skyblock_id).values.
#      find_all { |arr| arr.size > 1 && arr.count{ |stack| stack.size < stack.maxCount } > 1 }
#    exit
#  end

  def method_missing mname, *args, &block
    @stacks.send(mname, *args, &block)
  end
end

