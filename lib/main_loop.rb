require 'bundler/setup'
require 'pallet.rb'

class MainLoop
  def initialize
  end

  def run
    key = nil
    quit = false
    current_pallet = Pallet.load_from_file("pallet.yml")
    cur_line = Curses.lines / 2
    main_window
    loop do
        main_window.setpos(cur_line, Curses.cols / 2)
        main_window.addstr(key.to_s)
        cur_line += 1

      current_pallet.pallet.keys.each{ |key|
        color_name = key
        main_window.color_set( current_pallet.find_slot_by_name(key)[:index] )
        main_window.setpos(cur_line, Curses.cols / 2)
        main_window.addstr("X")
        main_window.color_set(0)
        main_window.addstr(" " + color_name)

        cur_line += 1
      }

        main_window.setpos(Curses.lines - 1, Curses.cols / 2)
        main_window.addstr("Press Enter to Quit")
      main_window.refresh
      key = [main_window.getch]
      if key == [27]
        sleep 0.01
        key << main_window.getch
        if key[1] == '['
      end

      quit = true if [13].include? key
      break if quit
    end 
    main_window.close
    @main_window = nil
  end

  def main_window
    @main_window ||= (
      setup_screen
      setup_pallet
      setup_keyboard

      Curses::Window.new(*([0] * 4))
    )
  end

  def setup_screen
      Curses.init_screen 
      Curses.start_color 
  end

  def setup_keyboard
      Curses.noecho
      Curses.nonl
      Curses.stdscr.keypad(true)
      Curses.raw
        Curses.mousemask(Curses::BUTTON1_CLICKED|Curses::BUTTON2_CLICKED|Curses::BUTTON3_CLICKED|Curses::BUTTON4_CLICKED)

     #Curses.crmode # mouse?
      Curses.stdscr.nodelay = 1
  end

  def setup_pallet(pallet = Pallet.load_from_file("pallet.yml"))
    pallet.set_active_pallet
  end
end

