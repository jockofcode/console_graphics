#!/usr/bin/env ruby -Iapp -Ilib

require 'console_access.rb'

@app = ConsoleAccess.new
start_time = Time.now
quit = false

def select_color(number)
  ::FFI::NCurses.color_set(number, nil)
end

def move_to_pos(x,y)
  ::FFI::NCurses.wmove(@app.main_window, y, x)
end

def print_string(string)
  ::FFI::NCurses.addstr(string)
end

def write_buffer
  ::FFI::NCurses.wrefresh(@app.main_window)
end

def window_height
  ::FFI::NCurses.getmaxy(@app.main_window) - 1
end

def window_width
  ::FFI::NCurses.getmaxx(@app.main_window)
end

@app.run_loop { |window, events|
  event = @app.events.shift

  time = Time.now.to_s
  move_to_pos(((window_width - time.length)  / 2), 0)
  print_string(Time.now.to_s)
  move_to_pos(0,0)

  if event
    quit = true if [13,3,26,27].include?(event.data.char) # Ctrl<C>, Ctrl<Z>, Enter, or <ESC>
  end

  write_buffer
  :quit if quit
}
