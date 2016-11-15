#!/usr/bin/env ruby -Iapp -Ilib
#require 'bundler/setup'
require 'console_access.rb'

app = ConsoleAccess.new
start_time = Time.now
print_char = "$"
last_coords = [0,0] 
quit = false


app.run_loop { |event|
#  event = app.events.shift
  if event
    File.open("~event.yml","a"){|f| f << "count: #{app.events.count}\n" + event.to_yaml }
    last_coords = [event.data.lines,event.data.cols] if event.type == :mouse && event.method == :button_down
    app.quit = true if [13,3,26].include?(event.data.char) # Ctrl<C>, Ctrl<Z>, Enter

    ::FFI::NCurses.wmove(app.main_window, *last_coords)
    ::FFI::NCurses.color_set(1, nil)
    ::FFI::NCurses.addstr(print_char)
    ::FFI::NCurses.color_set(0, nil)

  end

  # Update status at the bottom, even if no event happened
  ::FFI::NCurses.wmove(app.main_window, ::FFI::NCurses.getmaxy(app.main_window) - 1, ::FFI::NCurses.getmaxx(app.main_window) / 2)
  ::FFI::NCurses.addstr("#{last_coords.first}x#{last_coords.last} Press Enter to Quit")
  ::FFI::NCurses.wrefresh(app.main_window)
}
