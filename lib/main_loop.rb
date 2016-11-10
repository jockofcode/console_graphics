require 'bundler/setup'
require 'pallet.rb'

class MainLoop
  def initialize
  end

  def run
    keys_pressed = []
    quit = false
    current_pallet = Pallet.load_from_file("pallet.yml")
    cur_line = Curses.lines / 2
   #main_window
      last_coords = [Curses.cols, Curses.lines]
    loop do
      last_coords = keys_pressed[4..5] if keys_pressed != [] && keys_pressed[3] == :button_down && keys_pressed[2] == "M"
      main_window.setpos(*last_coords)
      main_window.color_set(1)
      main_window.addstr("#")
      main_window.color_set(0)
      #main_window.color_set( current_pallet.find_slot_by_name(1)[:index] )
      #main_window.setpos(cur_line, Curses.cols / 2)
      #main_window.addstr(" " + color_name) unless keys_pressed.empty?

      main_window.setpos(Curses.lines - 1, Curses.cols / 2)
      main_window.addstr("#{last_coords.first}x#{last_coords.last} Press Enter to Quit")
      main_window.refresh
      keys_pressed = get_key
      File.open("~keys_pressed.yml","a"){|f| f << keys_pressed.to_yaml } if !keys_pressed.empty?
      quit = true if [[13],[3],[26]].include? keys_pressed
      break if quit
    end
    main_window.close
    Curses.noraw
    Curses.crmode
    Curses.echo
    @main_window = nil
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

  def get_key
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
          3.times{
            keys << main_window.getch
          }
        end
      end
    end
    keys.compact!
    return keys
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

