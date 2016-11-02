

class Pallet
  attr_accessor :pallet
  def self.load_from_file(filename)
    if !File.exists?(filename)
      File.open(filename,"w") {|f| f << {}.to_yaml }  
    end

    p = self.class.new
    p.pallet = YAML.load(File.read(filename))
  end

  def save(filename)
      File.open(filename,"w") {|f| f << @pallet.to_yaml }  
  end

  def initialize
    @pallet = {}
  end

  def add_color(name, fg, bg)
    existing_slot = find_slot_by_name(name)
    if existing_slot
      existing_slot[:fg] = fg
      existing_slot[:bg] = bg
      return name
    end

    existing_number = find_slots_by_color_pair(fg, bg).map{|slot| slot[:number] }.uniq.first

    if existing_number
      @pallet[name] = {number: existing_number, bg: bg, fg: fg}
      return name
    end

    next_number = ((1..255).to_a - @pallet.map{|k,v| v[:number]}).sort.first
    if next_number == nil
      puts "No slots left for color"
      return
    else
      @pallet[name] = {number: next_number, bg: bg, fg: fg}
    end
  end

  def remove_color(color)
    if color.is_a?(Numeric)
      color_slots = find_slots_by_number(color)
    elsif color.is_a?(String)
      color_slots = [find_slot_by_name(color)].compact
    elsif color.is_a?(Array)
      color_slots = find_slots_by_color_pair(*color)
    end

    color_slots.each{|slot| slot.delete }
  end

  def find_slot_by_name(name)
    @pallet[name]
  end
  def find_slots_by_number(number)
    @pallet.select{|n,v| v[:number] == number}
  end
  def find_slots_by_color_pair(fg, bg)
    @pallet.select{|n,v| v[:bg] == bg && v[:fg] == fg }
  end
end
