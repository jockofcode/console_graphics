require 'bundler/setup'
require 'pallet.rb'
require 'ostruct'
require 'ffi-ncurses'

class ConsoleAccess
  class Event
    attr_accessor :type, :method, :data
    def initialize(type = nil)
      @type = type
      @method = nil
      @data = OpenStruct.new
    end

    def type=(new_type)
      @type = new_type.to_sym
    end
  end

  attr_accessor :main_window, :current_pallet, :events, :print_char, :quit

  def initialize(show_cursor: true, pallet_file_name: "pallet.yml")
    @event_checks = []
    @events = []
    @event_blocks = {}
    @quit = false
    @current_pallet = Pallet.load_from_file(pallet_file_name)
    setup_screen
    setup_pallet
    setup_input
    self.show_cursor(show_cursor)
  end

  def register_event_trigger(event_type, &block)
    event = OpenStruct.new
    event.check = block
    event.type = event_type
    @event_checks << event
  end

  def register_event(event_type, &block)
    @event_blocks[event_type] = block
  end

  def select_color(number)
    ::FFI::NCurses.color_set(number, nil)
  end

  def move_to_pos(x,y)
    ::FFI::NCurses.wmove(main_window, y, x)
  end

  def print_string(string)
    ::FFI::NCurses.waddstr(main_window,string)
  end

  def write_buffer
    ::FFI::NCurses.wrefresh(main_window)
  end

  def window_height
    ::FFI::NCurses.getmaxy(main_window) - 1
  end

  def window_width
    ::FFI::NCurses.getmaxx(main_window)
  end

  def show_cursor(visible = true)
    ::FFI::NCurses.curs_set( visible ? 1 : 0 )
  end

  def run_loop
    begin
#      main_window # Needs to be initialized before events can be checked for
      loop do
        event_happened = check_for_event
        if event_happened
            event = @events.shift
          if @event_blocks.has_key?(event.type)
            @event_blocks[event.type].call(event)
          end
          break if @quit
        end
      end
    ensure
      shutdown_screen
    end
  end

  def main_window
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

  def send_event(event)
    #should put a semaphore/mutex around this...
    @events << event
  end

  def check_for_event
    event_happened = false

    @event_checks.each{|event_check|
      result =  event_check.check.call
      if result != nil
        event_happened = true
        event = self.class::Event.new(event_check.type)
        event.method = nil
        event.data = result
        send_event(event)
      end
    }

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
      event_happened = true
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
      send_event(event)
    end
    return event_happened
  end

  def setup_screen
    @main_window = ::FFI::NCurses.initscr
    ::FFI::NCurses.start_color
    ::FFI::NCurses.wtimeout(@main_window, 0)
  end

  def shutdown_screen
    ::FFI::NCurses.curs_set 1
    ::FFI::NCurses.noraw
    ::FFI::NCurses.echo
    ::FFI::NCurses.endwin
    @main_window = nil
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

