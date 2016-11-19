#!/usr/bin/env ruby -Iapp -Ilib
#require 'bundler/setup'
require 'event_loop.rb'

app = EventLoop.new
start_time = Time.now
print_char = "$"
last_coords = [0,0]

app.run { |event|
  if event
    File.open("~event.yml","a"){|f| f << "count: #{app.events.count}\n" + event.to_yaml }
    last_coords = [event.data.lines,event.data.cols] if event.type == :mouse && event.method == :button_down
    app.quit = true if [13,3,26].include?(event.data.char) # Ctrl<C>, Ctrl<Z>, Enter

    app.move_to_pos(*last_coords)
    app.select_color(1)
    app.print_string(print_char)
    app.select_color(0)
  end

  # Update status at the bottom, even if no event happened
   app.move_to_pos(app.window_width - 1, app.window_height / 2)
  # app.move_to_pos(app.window_height / 2, app.window_width - 1)
  # ::FFI::NCurses.wmove(app.main_window, ::FFI::NCurses.getmaxy(app.main_window) - 1, ::FFI::NCurses.getmaxx(app.main_window) / 2)
    app.print_string("#{last_coords.first}x#{last_coords.last} Press Enter to Quit")
   #::FFI::NCurses.wrefresh(app.main_window)
   app.write_buffer
}
