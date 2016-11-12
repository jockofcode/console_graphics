require 'bundler/setup'
require 'pallet.rb'
require 'ostruct'
require 'ffi-ncurses'

class ConsoleAccess
  class Event
    attr_accessor :type, :method, :data
    def initialize
      @type = nil
      @method = nil
      @data = OpenStruct.new
    end

    def type=(new_type)
      @type = case new_type
              when :keyboard
                new_type
              when :mouse
                new_type
              when :screen
                new_type
              else
                raise "unknown event type: #{new_type}"
              end
    end
  end

  attr_accessor :main_window, :current_pallet, :events, :print_char

  def initialize
    #    @print_char = "#"
  end

  def run_loop
    begin
      @events = []
      @current_pallet = Pallet.load_from_file("pallet.yml")
      quit = false
      loop do
        check_for_event
        quit = (yield(main_window, @events)==:quit ? true : false)

        break if quit
      end
    ensure
      ::FFI::NCurses.noraw
      ::FFI::NCurses.echo
      FFI::NCurses.endwin
      @main_window = nil
    end
  end

  def demo
    @last_coords ||= [0,0] 
    event = events.shift
    if event
      File.open("~event.yml","a"){|f| f << "count: #{@events.count}\n" + event.to_yaml }
      @last_coords = [event.data.lines,event.data.cols] if event.type == :mouse && event.method == :button_down
      quit = true if [13,3,26].include?(event.data.char) # Ctrl<C>, Ctrl<Z>, Enter
    end

    ::FFI::NCurses.wmove(main_window, *@last_coords)
    ::FFI::NCurses.color_set(1, nil)
    ::FFI::NCurses.addstr(@print_char)
    ::FFI::NCurses.color_set(0, nil)

    ::FFI::NCurses.wmove(main_window, ::FFI::NCurses.getmaxy(@main_window) - 1, ::FFI::NCurses.getmaxx(@main_window) / 2)
    ::FFI::NCurses.addstr("#{@last_coords.first}x#{@last_coords.last} Press Enter to Quit")
    ::FFI::NCurses.wrefresh(@main_window)
    :quit if quit
  end

  def main_window
    if !@main_window
      setup_screen
      setup_pallet
      setup_input
    end
    @main_window
  end

  def read_key_byte
    next_byte = ::FFI::NCurses.getch
    next_byte = nil if next_byte == -1
    if next_byte.class == Fixnum
    elsif next_byte.class == String
      next_byte = next_byte.bytes.first
    elsif next_byte.class == NilClass
    else
      raise "datatype not anticipated: #{next_byte.class.to_s}"
    end
    next_byte
  end

  def check_for_event 
    keys = []
    keys << read_key_byte # If I get input from Curses.getch, it pauses on <esc>
    if keys.last == 27
      keys << read_key_byte
      if keys.last == "[".bytes.first
        keys << read_key_byte
        if keys.last == "M".bytes.first
          keys << case read_key_byte
          when "#".bytes.first
            :button_up
          when " ".bytes.first
            :button_down
          end

          keys << read_key_byte - 33
          keys << read_key_byte - 33

          keys[4], keys[5] = keys[5], keys[4]
        end
      end
    end
    keys.compact!
    if !keys.empty?
      event = self.class::Event.new
      if keys[2] == "M".bytes.first
        event.type = :mouse
        event.method = keys[3]
        event.data.lines = keys[4]
        event.data.cols = keys[5]
      elsif keys[0] == 410
        event.type = :screen
        current_screen_size = [::FFI::NCurses.getmaxyx(@main_window,nil,nil)]
        event.data.size = current_screen_size.dup
      else
        event.type = :keyboard
        event.data.char = keys.first
      end
      @events << event
    end
  end

  def setup_screen
    @main_window = ::FFI::NCurses.initscr 
    ::FFI::NCurses.start_color 
    ::FFI::NCurses.wtimeout(@main_window, 0)
  end

  def setup_input
    ::FFI::NCurses.noecho
    ::FFI::NCurses.nonl
    #main_window.keypad(false)
    ::FFI::NCurses.keypad(@main_window, 0) #TODO probably want this true for mouse...
    ::FFI::NCurses.raw
    ::FFI::NCurses.mousemask(
      ::FFI::NCurses::BUTTON1_PRESSED|
      ::FFI::NCurses::BUTTON1_RELEASED|
      ::FFI::NCurses::BUTTON1_CLICKED|
      ::FFI::NCurses::BUTTON1_DOUBLE_CLICKED|
      ::FFI::NCurses::BUTTON1_TRIPLE_CLICKED|
      ::FFI::NCurses::BUTTON2_PRESSED|
      ::FFI::NCurses::BUTTON2_RELEASED|
      ::FFI::NCurses::BUTTON2_CLICKED|
      ::FFI::NCurses::BUTTON2_DOUBLE_CLICKED|
      ::FFI::NCurses::BUTTON2_TRIPLE_CLICKED|
      ::FFI::NCurses::BUTTON3_PRESSED|
      ::FFI::NCurses::BUTTON3_RELEASED|
      ::FFI::NCurses::BUTTON3_CLICKED|
      ::FFI::NCurses::BUTTON3_DOUBLE_CLICKED|
      ::FFI::NCurses::BUTTON3_TRIPLE_CLICKED|
      ::FFI::NCurses::BUTTON4_PRESSED|
      ::FFI::NCurses::BUTTON4_RELEASED|
      ::FFI::NCurses::BUTTON4_CLICKED|
      ::FFI::NCurses::BUTTON4_DOUBLE_CLICKED|
      ::FFI::NCurses::BUTTON4_TRIPLE_CLICKED|
      ::FFI::NCurses::BUTTON_SHIFT|
      ::FFI::NCurses::BUTTON_CTRL|
      ::FFI::NCurses::BUTTON_ALT|
      ::FFI::NCurses::ALL_MOUSE_EVENTS|
      ::FFI::NCurses::REPORT_MOUSE_POSITION,
        nil
    )
  end

  def setup_pallet(pallet = Pallet.load_from_file("pallet.yml"))
    pallet.set_active_pallet
  end
end

