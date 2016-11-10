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
    main_window
    loop do
      cur_line = Curses.lines / 2
      main_window.setpos(cur_line, Curses.cols / 2)
      main_window.addstr(keys_pressed.to_s) unless keys_pressed.empty?
      cur_line += 1

      current_pallet.pallet.keys.each{ |key|
        color_name = key
        main_window.color_set( current_pallet.find_slot_by_name(key)[:index] )
        main_window.setpos(cur_line, Curses.cols / 2)
        main_window.addstr("X") unless keys_pressed.empty?
        main_window.color_set(0)
        main_window.addstr(" " + color_name) unless keys_pressed.empty?

        cur_line += 1
      }

      main_window.setpos(Curses.lines - 1, Curses.cols / 2)
      main_window.addstr("Press Enter to Quit")
      main_window.refresh
      keys_pressed = get_key
      File.open("keys_pressed.yml","a"){|f| f << keys_pressed.to_yaml } if !keys_pressed.empty?
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
    keys << main_window.getch
    if keys.last == 27
      keys << main_window.getch
      if keys.last == "["
        keys << main_window.getch
        if keys.last == "M"
          3.times{
            keys << main_window.getch
          }
        end
      end
    end
    keys.compact!
    keys
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
    Curses.mousemask(Curses::BUTTON1_CLICKED|Curses::BUTTON2_CLICKED|Curses::BUTTON3_CLICKED|Curses::BUTTON4_CLICKED)

    #Curses.crmode # mouse?
   #Curses.delay=0
  end

  def setup_pallet(pallet = Pallet.load_from_file("pallet.yml"))
    pallet.set_active_pallet
  end
end

