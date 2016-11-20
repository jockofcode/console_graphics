require 'bundler/setup'

require 'console_graphics/pallet.rb'
require 'ostruct'
require 'ffi-ncurses'

module ConsoleGraphics
  class EventLoop
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

    # Should move to key processing class, outside of generic event class
    SPECIAL_KEY_MAP = {
      23361 => :up_arrow,
      23362 => :down_arrow,
      23363 => :right_arrow,
      23364 => :left_arrow,
    }

    attr_accessor :current_pallet, :events, :print_char, :quit

    def initialize(display: NCursesDisplay, keyreader: NCursesKeyReader, mousereader: NCursesMouseReader, show_cursor: true, pallet_file_name: "pallet.yml")
      @event_checks = []
      @events = []
      @event_blocks = {}
      @named_event_blocks = {}
      @quit = false
      @current_pallet = Pallet.load_from_file(pallet_file_name)
      @display = display&.new
      @keyboard = keyreader&.new
      @mouse = mousereader&.new

      setup_pallet
      self.show_cursor(show_cursor)

      at_exit do
        @keyboard&.destroy
        @display&.destroy
        @mouse&.destroy
        puts "Keyboard and Display reset back to normal"
        exit 0
      end
    end

    def on_event_trigger(event_type, &block)
      event = OpenStruct.new
      event.check = block
      event.type = event_type
      @event_checks << event
    end

    def on_event(event_type, responder_name = nil,  &block)
      @event_blocks[event_type] = block
      @named_event_blocks[responder_name] = block if responder_name
    end

    def remove_event_responder(responder_name)
      @event_blocks.reject!{|event_type, responder|
        @named_event_blocks[responder_name] == responder
      }
    end

    def select_color(number)
      @display.select_color(number)
    end

    def move_to_pos(x,y)
      @display.move_to_pos(x,y)
    end

    def print_string(string)
      @display.print_string(string)
    end

    def clear_screen
      @display.clear_screen
    end

    def write_buffer
      @display.write_buffer
    end
    alias_method :refresh, :write_buffer

    def window_height
      @display.window_height
    end

    def window_width
      @display.window_width
    end

    def show_cursor(visible = true)
      @display.show_cursor(visible)
    end

    def getch
      @keyboard.getch
    end

    def run
      loop do
        event_happened = check_for_event
        local_events = @events.dup
        @events = []
        if event_happened
          local_events.each do |event|
            if @event_blocks.has_key?(event.type)
              @event_blocks[event.type].call(event)
            else
              yield event if block_given?
            end
          end
          break if @quit
        end
      end
    end

    def read_key_byte
      next_byte = @keyboard.getch 
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
        elsif (65..68).include?(keys[2]) # A..D
          event.type = :keyboard
          event.data.char = (ks = keys[1..2]; (ks[0] * 256) + ks[1])
        elsif keys[0] == 410
          event.type = :screen
          current_screen_size = @display.screen_size  
          event.data.size = current_screen_size.dup
        else
          event.type = :keyboard
          event.data.char = keys.first
        end
        send_event(event)
      end
      return event_happened
    end


    def setup_pallet(pallet = Pallet.load_from_file("pallet.yml"))
      pallet.set_active_pallet
    end

  end

  class NCursesKeyReader
    def initialize
      setup
    end

    def setup
      # ::FFI::NCurses.keypad(@main_window, 0) #TODO probably want this true for mouse...
      ::FFI::NCurses.raw
      ::FFI::NCurses.noecho
      ::FFI::NCurses.nonl
    end

    def destroy
      ::FFI::NCurses.noraw
      ::FFI::NCurses.echo
      ::FFI::NCurses.nl
    end

    def getch
      ::FFI::NCurses.getch
    end
  end

  class NCursesMouseReader

    def initialize
      setup
    end

    def setup
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

    def destroy
    end
  end

  class NCursesDisplay
    attr_accessor :main_window
    def initialize
      setup
    end

    def setup
      @main_window = ::FFI::NCurses.initscr
      ::FFI::NCurses.start_color
      ::FFI::NCurses.wtimeout(@main_window, 0)
    end

    def destroy
      ::FFI::NCurses.curs_set 1
      ::FFI::NCurses.noraw
      ::FFI::NCurses.echo
      ::FFI::NCurses.endwin
      @main_window = nil
    end

    def select_color(number)
      ::FFI::NCurses.color_set(number, nil)
    end

    def move_to_pos(x,y)
      # ::FFI::NCurses.wmove(@main_window, y, x)
      ::FFI::NCurses.move(y, x)
    end

    def print_string(string)
      # ::FFI::NCurses.waddstr(@main_window,string)
      ::FFI::NCurses.addstr(string)
    end

    def clear_screen
      ::FFI::NCurses.clear
      # ::FFI::NCurses.wclear(@main_window)
    end

    def write_buffer
      # ::FFI::NCurses.wrefresh(@main_window)
      ::FFI::NCurses.refresh
    end

    def window_height
      ::FFI::NCurses.getmaxy(@main_window) - 1
    end

    def window_width
      ::FFI::NCurses.getmaxx(@main_window)
    end

    def screen_size
      [::FFI::NCurses.getmaxyx(@main_window,nil,nil)]
    end

    def show_cursor(visible = true)
      ::FFI::NCurses.curs_set( visible ? 1 : 0 )
    end
  end
end
