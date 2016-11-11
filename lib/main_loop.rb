require 'bundler/setup'
require 'pallet.rb'
require 'ostruct'

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
      else
        raise "unknown event type: #{new_type}"
      end
    end
  end

  def initialize
  end

  def run_loop
    @events = []
    @current_pallet = Pallet.load_from_file("pallet.yml")
    quit = false
    loop do
      check_for_key_mouse_event
      if block_given? 
        quit = (yield(main_window, @events)==:quit ? true : false)
      else
        quit = (demo(main_window, @events)==:quit ? true : false)
      end

      break if quit
    end
    main_window.close
    Curses.noraw
    Curses.crmode
    Curses.echo
    @main_window = nil
  end

  def demo(main_window, events)
    @last_coords ||= [0,0] 
    event = events.shift
    if event
      @last_coords = [event.data.lines,event.data.cols] if event.type == :mouse && event.method == :button_down
      File.open("~event.yml","a"){|f| f << event.to_yaml }
      quit = true if [13,3,26].include?(event.data.char)
    end

    main_window.setpos(*@last_coords)
    main_window.color_set(1)
    main_window.addstr("#")
    main_window.color_set(0)

    main_window.setpos(Curses.lines - 1, Curses.cols / 2)
    main_window.addstr("#{@last_coords.first}x#{@last_coords.last} Press Enter to Quit")
    main_window.refresh
    :quit if quit
  end

  def main_window
    if !@main_window
      @main_window = Curses::Window.new(*([0] * 4))
      setup_screen
      setup_pallet
      setup_keyboard
    end
    @main_window
  end

  def check_for_key_mouse_event 
    keys = []
    keys << main_window.getch # If I get input from Curses.getch, it pauses on <esc>
    if keys.last == 27
      keys << main_window.getch
      if keys.last == "["
        keys << main_window.getch
        if keys.last == "M"
          keys << case main_window.getch
          when "#"
            :button_up
          when " "
            :button_down
          end

          keys << main_window.getch.bytes.first - 33
          keys << main_window.getch.bytes.first - 33
          keys[4], keys[5] = keys[5], keys[4]
        end
      end
    end
    keys.compact!
    if !keys.empty?
      event = self.class::Event.new
      if keys[2] == "M"
        event.type = :mouse
        event.method = keys[3]
        event.data.lines = keys[4]
        event.data.cols = keys[5]
      else
        event.type = :keyboard
        event.data.char = keys.first
      end
      @events << event
      File.open("~event.yml","a"){|f| f << "count: #{@events.count}\n" + event.to_yaml }
    end
  end

  def setup_screen
    Curses.init_screen 
    Curses.start_color 
    main_window.timeout= 0 #nodelay = 1
  end

  def setup_keyboard
    Curses.noecho
    Curses.nonl
    main_window.keypad(false)
    Curses.raw
    Curses.mousemask(
      Curses::BUTTON1_PRESSED|
      Curses::BUTTON1_RELEASED|
      Curses::BUTTON1_CLICKED|
      Curses::BUTTON1_DOUBLE_CLICKED|
      Curses::BUTTON1_TRIPLE_CLICKED|
      Curses::BUTTON2_PRESSED|
      Curses::BUTTON2_RELEASED|
      Curses::BUTTON2_CLICKED|
      Curses::BUTTON2_DOUBLE_CLICKED|
      Curses::BUTTON2_TRIPLE_CLICKED|
      Curses::BUTTON3_PRESSED|
      Curses::BUTTON3_RELEASED|
      Curses::BUTTON3_CLICKED|
      Curses::BUTTON3_DOUBLE_CLICKED|
      Curses::BUTTON3_TRIPLE_CLICKED|
      Curses::BUTTON4_PRESSED|
      Curses::BUTTON4_RELEASED|
      Curses::BUTTON4_CLICKED|
      Curses::BUTTON4_DOUBLE_CLICKED|
      Curses::BUTTON4_TRIPLE_CLICKED|
      Curses::BUTTON_SHIFT|
      Curses::BUTTON_CTRL|
      Curses::BUTTON_ALT|
      Curses::ALL_MOUSE_EVENTS|
      Curses::REPORT_MOUSE_POSITION
    )

    #Curses.crmode # mouse?
   #Curses.delay=0
  end

  def setup_pallet(pallet = Pallet.load_from_file("pallet.yml"))
    pallet.set_active_pallet
  end
end

