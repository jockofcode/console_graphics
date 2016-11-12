require 'yaml'

class Pallet
  attr_accessor :pallet

  def get_active_curses_pallet
    @pallet.select{|k,v| v[:index] }.map{|k,v| [v[:index],v[:fg], v[:bg]] }.uniq
  end

  def set_active_pallet
    get_active_curses_pallet.each do |color_index_and_pair|
      FFI::NCurses.init_pair(*color_index_and_pair)
    end
  end
  
  def self.load_from_file(filename)
    if !File.exists?(filename)
      File.open(filename,"w") {|f| f << {}.to_yaml }  
    end

    p = new
    p.pallet = YAML.load(File.read(filename))

    p
  end

  def save(filename)
      File.open(filename,"w") {|f| f << @pallet.to_yaml }  
      true
  end

  def initialize
    @pallet = {}
  end

  def add_color(name, fg, bg, options = {create_new_index: true})
    existing_slot = find_slot_by_name(name)
    existing_index = find_slots_by_color_pair(fg, bg).map{|slot| slot.last[:index] }.uniq.first
    next_index = ((1..255).to_a - @pallet.map{|k,v| v[:index]}).sort.first

    if existing_slot
      remove_color(name)
      @pallet[name] = {index: next_index, fg: fg, bg: bg}
      return name
    end

    if existing_index
      @pallet[name] = {index: existing_index, fg: fg, bg: bg}
      return name
    end

    next_index = ((1..255).to_a - @pallet.map{|k,v| v[:index]}).sort.first

    if next_index == nil || options[:create_new_index] != true
      puts "No slots left for color"
      @pallet[name] = {index: nil, fg: fg, bg: bg}
      return name
    else
      @pallet[name] = {index: next_index, fg: fg, bg: bg}
      return name
    end
  end

  def remove_color(color)
    if color.is_a?(Numeric)
      color_slots = find_slots_by_index(color)
    elsif color.is_a?(String)
      color_slots = [find_slot_by_name(color)].compact
    elsif color.is_a?(Array)
      color_slots = find_slots_by_color_pair(*color)
    end
    color_slots.each{|slot| slot.delete }

    return color_slots
  end

  def remove_index(color)
    if color.is_a?(Numeric)
      color_slots = find_slots_by_index(color)
    elsif color.is_a?(String)
      color_slots = [find_slot_by_name(color)].compact
    elsif color.is_a?(Array)
      color_slots = find_slots_by_color_pair(*color)
    end
    color_slots.each{|slot| slot.last[:index] = nil }

    return color_slots
  end

  def find_slot_by_name(name)
    @pallet[name]
  end
  def find_slots_by_index(index)
    @pallet.select{|n,v| v[:index] == index}
  end
  def find_slots_by_color_pair(fg, bg)
    @pallet.select{|n,v| v[:bg] == bg && v[:fg] == fg }
  end
end
